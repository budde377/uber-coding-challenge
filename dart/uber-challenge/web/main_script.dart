import "dart:html";
import "package:google_maps/google_maps.dart" as Maps;
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

  Position.fromLatLong(Maps.LatLng pos) : this((pos.lat * 1000000).toInt(), (pos.lng * 1000000).toInt());

  String toString() => "Postion[$lat:$long]";

  Maps.LatLng get latlng => new Maps.LatLng(lat / 1000000, long / 1000000);

}

Future _ajaxCall(String command) async {
  var result = await HttpRequest.getString("/api/1.0/$command");
  return JSON.decode(result);
}

class Departure {

  static final Map<int, Departure>_cache = {};

  final Station station;
  final String type, direction, name;
  final DateTime time;

  final StreamController<Departure> _on_departure_controller = new StreamController.broadcast();

  factory Departure(Station station, String type, String direction, String name, DateTime time) =>
  _cache.putIfAbsent(station.hashCode ^ type.hashCode ^ direction.hashCode ^ name.hashCode ^ time.hashCode,
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
  final UListElement _station_list;
  final Map<Station, LIElement> _station_li_map = {};
  final Map<Station, UListElement> _station_departure_map = {};
  final Map<Departure, LIElement>_departure_li_map = {};
  Function _auto_update_callback;
  Station _active_station;

  TimeTableStyler(Element element, this.maps_styler) : super(element), _station_list = element.querySelector('ul.stations');


  setup() {
    maps_styler.onStationViewChange.listen(_setupStations);
  }

  void _setupStations(List<Station> station_list) {
    _station_list.children.clear();
    station_list.forEach(_setupStation);
    maps_styler.onActiveChange.listen((Station station) {
      if (station == null) {
        _hideDepartures();
      } else {
        _showDepartures(station);
      }
    });
  }

  void _setupStation(Station station) {
    LIElement li;
    if (_station_li_map.containsKey(station)) {
      li = _station_li_map[station];
    } else {
      var departure_list = new UListElement();
      departure_list
        ..classes.add('departure_list');

      var title = new SpanElement()
        ..onClick.listen((_) => _toggleDeparture(station))
        ..classes.add('title')
        ..text = station.name;
      var update = new SpanElement()
        ..onClick.listen((_) => _showDepartures(station))
        ..classes.add('update');

      li = new LIElement()
        ..append(title)
        ..append(update)
        ..append(departure_list);

      _station_departure_map[station] = departure_list;
      _station_li_map[station] = li;

    }
    _station_list.append(li);
  }

  _toggleDeparture(Station station) {
    if (maps_styler.active == station) {
      maps_styler.active = null;
    } else {
      maps_styler.active = station;
    }

  }

  void _hideDepartures() {
    assert(_active_station != null);
    _station_li_map[_active_station].classes.remove('active');
  }

  _showDepartures(Station station) async {
    if (_active_station != null) {
      _station_li_map[_active_station].classes.remove('active');
    }
    _active_station = station;
    _station_li_map[station].classes
      ..add('active')
      ..remove('updateable');

    var departure_list = _station_departure_map[station];
    departure_list.classes.add('loading');
    var departures = await station.departures;
    departure_list.classes.remove('loading');

    departure_list.children.addAll(departures.map(_departureToLi));

  }


  LIElement _departureToLi(Departure departure) {
    if (_departure_li_map.containsKey(departure)) {
      return _departure_li_map[departure];
    }
    var short_name = formatName(departure.name);
    var name = new SpanElement()
      ..classes.add('name')
      ..text = short_name
      ..style.backgroundColor = "hsl(${short_name.hashCode % 360},100%, 60%)";
    var direction = new SpanElement()
      ..classes.add('direction')
      ..text = departure.direction;
    var ttd = new SpanElement()
      ..text = formatDuration(departure.ttd)
      ..classes.add('ttd');
    var li = new LIElement()
      ..append(name)
      ..append(direction)
      ..append(ttd);
    _autoUpdate(() => ttd.text = formatDuration(departure.ttd));
    departure.onDeparture.listen((_) {
      li.remove();
      _showUpdate(departure.station);
    });
    return _departure_li_map[departure] = li;
  }

  void _showUpdate(Station station) {
    _station_li_map[station].classes.add('updateable');
  }

  void _autoUpdate(callback()) {
    if (_auto_update_callback != null) {
      var old_callback = _auto_update_callback;
      _auto_update_callback = () {
        old_callback();
        callback();
      };
      return;
    }

    _auto_update_callback = callback;

    new Timer.periodic(new Duration(minutes:1), (Timer timer) {
      _auto_update_callback();
    });
  }
}

String formatDuration(Duration duration) {
  var minutes = duration.inMinutes;
  if (minutes <= 0) {
    return "Soon";
  }
  var hour_string = "";
  if (duration.inMinutes >= 60) {
    hour_string = "${duration.inHours} hour${duration.inHours != 1 ? "s" : ""} ";
  }
  minutes = minutes % 60;
  return "$hour_string$minutes minute${minutes != 1 ? "s" : ""}";
}

String formatName(String name) {
  var match;
  if ((match = new RegExp(r"^[a-zA-Z ]*[Bb]us ([0-9]+[A-Z]?)$").firstMatch(name)) != null) {
    return match.group(1);
  }
  if ((match = new RegExp(r"^([^\s]{2,}) [0-9]+$").firstMatch(name)) != null) {
    return match.group(1);
  }

  return name;
}

class Pair<F, S> {
  final F first;
  final S second;

  Pair(this.first, this.second);
}


class MapsStyler extends Styler {

  Maps.GMap _map_instance;
  Maps.Circle _location_circle;
  int _min_accuracy = 700;
  StreamController<int> _min_accuracy_controller = new StreamController.broadcast();
  StreamController<Station> _on_active_change_controller = new StreamController.broadcast();
  StreamController<List<Station>> _station_view_controller = new StreamController.broadcast();
  final Map<Station, Maps.Marker> _station_marker_map = {};
  Station _active;

  Maps.GMap get _map {
    if (_map_instance != null) {
      return _map_instance;
    }
    var mapStyler = new Maps.MapTypeStyler()
      ..visibility = Maps.MapTypeStylerVisibility.OFF;

    var mapStyle = new Maps.MapTypeStyle()
      ..featureType = Maps.MapTypeStyleFeatureType.TRANSIT_STATION
      ..stylers = [mapStyler];

    var mapOptions = new Maps.MapOptions()
      ..zoom = 16
      ..mapTypeId = Maps.MapTypeId.ROADMAP
      ..styles = [mapStyle];

    return _map_instance = new Maps.GMap(element, mapOptions);
  }

  BodyElement get _body => querySelector('body');


  Station get active => _active;

  Stream<Station> get onActiveChange => _on_active_change_controller.stream;

  Stream<List<Station>> get onStationViewChange => _station_view_controller.stream;

  set active(Station value) {
    _active = value;
    _on_active_change_controller.add(value);

  }

  set min_accuracy(int value) => _min_accuracy_controller.add(_min_accuracy = value);

  get min_accuracy => _min_accuracy;

  MapsStyler(Element element) : super(element);

  _setupMap() async {
    _body.classes.add('initializing');
    var location, accuracy;
    var hash_pair = _positionFromHash();
    if (hash_pair != null) {
      location = hash_pair.first.latlng;
      accuracy = hash_pair.second;
    } else {
      try {
        var position = await window.navigator.geolocation.getCurrentPosition(enableHighAccuracy:true);
        location = new Maps.LatLng(position.coords.latitude, position.coords.longitude);
        accuracy = position.coords.accuracy;
      } catch (e) {
        location = new Maps.LatLng(56.1897765, 10.2197742);
        accuracy = 700;
      }

    }
    window.onHashChange.listen((_) {
      var hash_pair = _positionFromHash();
      if (hash_pair == null) {
        return;
      }
      _setupMapAt(hash_pair.first.latlng, hash_pair.second);
    });
    _body.classes.add('has_location');
    _setupMapAt(location, accuracy);
    _min_accuracy_controller.stream.listen((int accuracy) => _setupMapAt(location, accuracy));
  }

  Pair<Position, int> _positionFromHash() {
    var match = new RegExp(r"^#([0-9]+)/([0-9]+)/([0-9]+)$").firstMatch(window.location.hash);
    if (match == null) {
      return null;

    }
    return new Pair(new Position(int.parse(match.group(1)), int.parse(match.group(2))), int.parse(match.group(3)));
  }


  _setupMapAt(Maps.LatLng position, num radius) async {
    print([position, radius]);
    radius = max(radius, _min_accuracy);
    var station_list = await stations.stations_nearby(new Position.fromLatLong(position), radius);
    _map.center = position;
    _draw_stations(station_list, position, radius);
    onActiveChange.listen(_changeMarker);
    _body.classes
      ..remove('has_location')
      ..remove('initializing');
  }

  _draw_stations(List<Station> station_list, Maps.LatLng pos, num radius) {
    _draw_location(pos, radius);
    _station_marker_map.forEach((station, Maps.Marker marker) => marker.map = null);
    _station_view_controller.add(station_list);
    station_list.forEach(_draw_station);

  }

  void _draw_station(Station station) {
    if (_station_marker_map.containsKey(station)) {
      _station_marker_map[station].map = _map;
      return;
    }

    var markerOptions = new Maps.MarkerOptions()
      ..position = station.position.latlng
      ..title = station.name
      ..map = _map
      ..icon = new LightCustomIcon();

    _station_marker_map[station] = new Maps.Marker(markerOptions)
      ..onClick.listen((_) => active = active == station ? null : station);

  }

  void _draw_location(Maps.LatLng position, num radius) {

    if (_location_circle == null) {
      var circleOptions = new Maps.CircleOptions()
        ..strokeWeight = 0
        ..fillOpacity = 0.1
        ..fillColor = "#76cbe3"
        ..clickable = false
        ..map = _map
        ..center = position
        ..radius = radius;
      _location_circle = new Maps.Circle(circleOptions);
    } else {
      _location_circle
        ..radius = radius
        ..center = position;
    }

  }


  void setup() {
    _setupMap();
  }


  void _changeMarker(Station station) {
    if (station == null) {
      return;
    }
    var marker = _station_marker_map[station]
      ..icon = new DarkCustomIcon();
    StreamSubscription subscription;
    subscription = onActiveChange.listen((_) {
      subscription.cancel();
      marker.icon = new LightCustomIcon();
    });
  }
}

class CustomIcon extends Maps.Icon {

  CustomIcon(String url) {
    anchor = new Maps.Point(24, 48);
    origin = new Maps.Point(0, 0);
    size = new Maps.Size(48, 48);
    this.url = url;

  }

}


class DarkCustomIcon extends CustomIcon {

  DarkCustomIcon() :super("/img/iconmonstr-location-icon-48-dark.png");

}


class LightCustomIcon extends CustomIcon {

  LightCustomIcon() :super("/img/iconmonstr-location-icon-48-light.png");

}
