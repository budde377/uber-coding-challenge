import "dart:html";
import "package:google_maps/google_maps.dart";
import 'dart:async';
import 'dart:convert';
import 'dart:math';


main() {

  var maps_styler = new MapsStyler(querySelector("#MapCanvas"));
  maps_styler.setup();
  var time_table_styler = new TimeTableStyler(querySelector('#Timetable'), maps_styler);
  time_table_styler.setup();
}

class Position {
  final int lat, long;

  Position(this.lat, this.long);

  Position.fromLatLong(LatLng pos) : this((pos.lat * 1000000).toInt(), (pos.lng * 1000000).toInt());

  String toString() => "Postion[$lat:$long]";

  LatLng get latlng => new LatLng(lat / 1000000, long / 1000000);

}

Future _ajaxCall(String command) async {
  var result = await HttpRequest.getString("/api/1.0/$command");
  return JSON.decode(result);
}

class Departure {

  final String type, direction, name;
  final DateTime time;

  Departure(this.type, this.direction, this.name, this.time);

  Departure.fromMap(Map departure): this(departure['departure_type'], departure['direction'], departure['name'], new DateTime.fromMillisecondsSinceEpoch(departure['date'] * 1000));

  String toString() => "Departure[$name:$type:$direction:$time]";


}

class Station {

  static final Map<int, Station> _cache = {};
  final int id;
  final String name;
  final Position position;

  factory Station(int id, String name, Position position) => _cache.putIfAbsent(id, () => new Station._internal(id, name, position));

  Station._internal(this.id, this.name, this.position);

  factory Station.fromMap(Map station) => new Station(station['id'], station['name'], new Position(station['pos']['lat'], station['pos']['long']));

  String toString() => "Station[$id:$name:$position]";

  Future<List<Departure>> get departures async{
    var result = await _ajaxCall("Stations/departures/$id");
    print(result);
    return result.map((Map departure) => new Departure.fromMap(departure));
  }

}

class Stations {

  static Stations _cache;

  Stations._internal();

  factory Stations() => _cache == null ? _cache = new Stations._internal() : _cache;

  final String url = "/api/1.0/";

  Future<List<Station>> stations_nearby(Position position, [int radius = 1000]) async {
    var result = await _ajaxCall("Stations/findNearby?lat=${position.lat}&long=${position.long}&radius=${radius}");
    return result.map((Map station) => new Station.fromMap(station));
  }


}

Stations get stations => new Stations();

abstract class Styler {

  final Element element;

  Styler(this.element);

  setup();
}

class TimeTableStyler extends Styler {

  final MapsStyler maps_styler;
  final UListElement departure_list;
  final Map<Station, LIElement> _station_list = {};

  TimeTableStyler(Element element, this.maps_styler) : super(element), departure_list = element.querySelector('ul.stations');


  @override
  setup() {
    maps_styler.onStationViewChange().listen(_setupStations);
  }

  void _setupStations(List<Station> station_list) {
    departure_list.children.clear();
    station_list.forEach(_setupStation);
  }

  void _setupStation(Station station) {
    LIElement li;
    if (_station_list.containsKey(station)) {
      li = _station_list[station];
    } else {
      li = new LIElement();
      li.text = station.name;
      var departure_list = new UListElement();
      departure_list.classes.add('departure_list');
      li.onClick.listen((_) => _toggleDeparture(station, departure_list));
      _station_list[station] = li;

    }
    departure_list.append(li);
  }

  _toggleDeparture(Station station, UListElement departure_list) async {
    var departures = await station.departures;
    print(departures);
  }
}

class MapsStyler extends Styler {

  GMap _map;
  Circle _location_circle;
  int _min_accuracy = 500;
  StreamController<int> _min_accuracy_controller = new StreamController.broadcast();
  StreamController<List<Station>> _station_view_controller = new StreamController.broadcast();
  final Map<Station, Marker> _station_marker_map = {};

  MapsStyler(Element element) : super(element);

  set min_accuracy(int value) {
    _min_accuracy_controller.add(_min_accuracy = value);
  }

  get min_accuracy => _min_accuracy;

  void setupMap() {
    element.classes.add('blur');
    window.navigator.geolocation.getCurrentPosition(enableHighAccuracy:true).then((Geoposition position) {
      setupMapAt(new LatLng(position.coords.latitude, position.coords.longitude), position.coords.accuracy);

    }, onError:(error) {
      setupMapAt(new LatLng(56.1897765, 10.2197742), 700);
    });
  }

  void setupMapAt(LatLng position, [num accuracy = 0]) {
    accuracy = max(accuracy, _min_accuracy);
    element.classes.remove('blur');
    //Disabling existing transit information
    var mapStyler = new MapTypeStyler()
      ..visibility = MapTypeStylerVisibility.OFF;

    var mapStyle = new MapTypeStyle()
      ..featureType = MapTypeStyleFeatureType.TRANSIT_STATION
      ..stylers = [mapStyler];

    var mapOptions = new MapOptions()
      ..zoom = 16
      ..center = position
      ..mapTypeId = MapTypeId.ROADMAP
      ..styles = [mapStyle];

    _map = new GMap(element, mapOptions);
    _draw_stations(position, accuracy);
    _min_accuracy_controller.stream.listen((int accuracy) => _draw_stations(position, accuracy));
  }

  dynamic _draw_stations(LatLng pos, [int radius = 300]) async {
    _draw_location(pos, radius);
    var position = new Position.fromLatLong(pos);
    var station_list = await stations.stations_nearby(position, radius);
    _station_view_controller.add(station_list);
    station_list.forEach(_draw_station);
  }

  void _draw_station(Station station) {
    if (_station_marker_map.containsKey(station)) {
      return;
    }
    var markerOptions = new MarkerOptions()
      ..position = station.position.latlng
      ..title = station.name
      ..map = _map;

    _station_marker_map[station] = new Marker(markerOptions);

  }

  void _draw_location(LatLng position, num accuracy) {

    if (_location_circle == null) {
      var circleOptions = new CircleOptions()
        ..strokeWeight = 0
        ..fillOpacity = 0.1
        ..fillColor = "#76cbe3"
        ..clickable = false
        ..map = _map
        ..center = position
        ..radius = accuracy;
      _location_circle = new Circle(circleOptions);
    } else {
      _location_circle.center = position;
    }

  }


  void setup() {
    setupMap();
  }

  Stream<List<Station>> onStationViewChange() => _station_view_controller.stream;
}

