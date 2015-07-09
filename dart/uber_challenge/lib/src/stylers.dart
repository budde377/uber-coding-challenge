part of uber_challenge;


abstract class Styler {

  final Element element;

  Styler(this.element);

  setup();
}

class TimeTableStyler extends Styler {

  final MapsStyler mapsStyler;
  final UListElement _station_list;
  final Map<Station, LIElement> _station_li_map = {};
  final Map<Station, UListElement> _station_departure_map = {};
  final Map<Departure, LIElement>_departure_li_map = {};
  Function _auto_update_callback;
  Station _active_station;

  TimeTableStyler(Element element, this.mapsStyler) : super(element), _station_list = element.querySelector('ul.stations');


  setup() {
    mapsStyler.onStationViewChange.listen(_setup_stations);
  }

  void _setup_stations(List<Station> station_list) {
    _station_list.children.clear();
    station_list.forEach(_setup_station);
    mapsStyler.onActiveChange.listen((Station station) {
      if (station == null) {
        _hide_departures();
      } else {
        _show_departures(station);
      }
    });
  }

  void _setup_station(Station station) {
    LIElement li;
    if (_station_li_map.containsKey(station)) {
      li = _station_li_map[station];
    } else {
      var departure_list = new UListElement();
      departure_list
        ..classes.add('departure_list');

      var title = new SpanElement()
        ..onClick.listen((_) => _toggle_departure(station))
        ..classes.add('title')
        ..text = station.name;
      var update = new SpanElement()
        ..onClick.listen((_) => _show_departures(station))
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

  _toggle_departure(Station station) {
    if (mapsStyler.active == station) {
      mapsStyler.active = null;
    } else {
      mapsStyler.active = station;
    }

  }

  void _hide_departures() {
    assert(_active_station != null);
    _station_li_map[_active_station].classes.remove('active');
  }

  _show_departures(Station station) async {
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

    departure_list.children.addAll(departures.map(_departure_to_li));

  }


  LIElement _departure_to_li(Departure departure) {
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
    _auto_update(() => ttd.text = formatDuration(departure.ttd));
    departure.onDeparture.listen((_) {
      li.remove();
      _show_update(departure.station);
    });
    return _departure_li_map[departure] = li;
  }

  void _show_update(Station station) {
    _station_li_map[station].classes.add('updateable');
  }

  void _auto_update(callback()) {
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

  _setup_map() async {
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
      showMapAt(hash_pair.first.latlng, hash_pair.second);
    });
    _body.classes.add('has_location');
    showMapAt(location, accuracy);
    _min_accuracy_controller.stream.listen((int accuracy) => showMapAt(location, accuracy));
  }

  Pair<Position, int> _positionFromHash() {
    var match = new RegExp(r"^#([0-9]+)/([0-9]+)/([0-9]+)$").firstMatch(window.location.hash);
    if (match == null) {
      return null;

    }
    return new Pair(new Position(int.parse(match.group(1)), int.parse(match.group(2))), int.parse(match.group(3)));
  }


  showMapAt(Maps.LatLng position, num radius) async {
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
    _setup_map();
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
