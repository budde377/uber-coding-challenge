part of uber_challenge;

Future _ajaxCall(String command) async {
  var result = await HttpRequest.getString("/api/1.0/$command");
  return JSON.decode(result);
}

/**
 * A class that models a position with latitude, longitude, and accuracy
 * It supports some conversion to and from Google Maps LatLng class
 */
class Position {
  final int lat, long, accuracy;

  Position(this.lat, this.long, [this.accuracy = 0]);

  Position.fromLatLong(Maps.LatLng pos, [num accuracy = 0]) : this.fromNum(pos.lat, pos.lng, accuracy);

  Position.fromNum(num lat, num long, [num accuracy = 0.0]) : this((lat * 1000000).toInt(), (long * 1000000).toInt(), accuracy.toInt());

  Position changeAccuracy(int accuracy) => new Position(lat, long, accuracy);

  String toString() => "Postion[$lat:$long:$accuracy]";

  Maps.LatLng get latlng => new Maps.LatLng(lat / 1000000, long / 1000000);

}

/**
 * Represents a departure.
 * The instances are created via. a factory which caches instances. This also clears the departure cache in
 * the Station instance.
 */
class Departure {

  static final Map<int, Departure>_cache = {};

  final Station station;
  final String type, direction, name;
  final DateTime time;

  final StreamController<Departure> _on_departure_controller = new StreamController.broadcast();

  factory Departure(Station station, String type, String direction, String name, DateTime time) =>
  _cache.putIfAbsent(station.hashCode ^ type.hashCode ^ direction.hashCode ^ name.hashCode ^ time.hashCode ^ station.id,
      () => new Departure._internal(station, type, direction, name, time));

  Departure._internal(this.station, this.type, this.direction, this.name, this.time){
    new Timer(ttd, () {
      station._departures = null;
      _on_departure_controller.add(this);
    });
  }

  factory Departure.fromMap(Station station, Map departure) =>
  new Departure(station, departure['departure_type'], departure['direction'], departure['name'], new DateTime.fromMillisecondsSinceEpoch((departure['date'] * 1000).toInt()));

  String toString() => "Departure[$name:$type:$direction:$time]";

  Duration get ttd => time.add(new Duration(minutes:1)).difference(new DateTime.now());

  Stream<Departure> get onDeparture => _on_departure_controller.stream;

}

/**
 * A representation of a station
 */
class Station {

  static final Map<int, Station> _cache = {};
  final int id;
  final String name;
  final Position position;
  List<Departure> _departures;

  factory Station(int id, String name, Position position) => _cache.putIfAbsent(id, () => new Station._internal(id, name, position));

  Station._internal(this.id, this.name, this.position);

  factory Station.fromMap(Map station) => new Station(station['id'], station['name'], new Position(station['pos']['lat'], station['pos']['long']));

  String toString() => "Station[$id:$name:$position]";

  Future<List<Departure>> get departures async{
    if (_departures != null) {
      return _departures;
    }
    List<Map> result = await _ajaxCall("Stations/departures/$id");
    return _departures = result.map((Map departure) => new Departure.fromMap(this, departure)).toList();

  }

}
/**
 * Finds the stations nearby
 */
Future<List<Station>> stationsNearby(Position position, [int radius = 1000]) async {
  var result = await _ajaxCall("Stations/findNearby?lat=${position.lat}&long=${position.long}&radius=${radius}");
  return result.map((Map station) => new Station.fromMap(station));
}

