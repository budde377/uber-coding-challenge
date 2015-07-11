part of uber_challenge;

/**
 * The Styler class "styles" an element by building sub-elements, attaching listeners, etc.
 */
abstract class Styler<E extends Element> {

  final E element;

  Styler(this.element);

  /**
   * Setup the element style
   */
  setup();
}


/**
 * The timetable is the element containing departure times for the stations currently beeing
 * displayed on the map (accessible through provided the MapsStyler instance)
 */
class TimeTableStyler extends Styler<UListElement> {

  final MapsStyler mapsStyler;
  final Map<Station, LIElement> _station_li_map = {};
  final Map<Station, UListElement> _station_departure_map = {};
  final Map<Departure, LIElement>_departure_li_map = {};
  Function _auto_update_callback;
  Station _active_station;

  TimeTableStyler(Element element, this.mapsStyler) : super(element);

  setup() {
    mapsStyler.onStationViewChange.listen(_setup_stations);
  }

  /**
   * Sets up the station-list, by adding LI-elements modeling the stations.
   * Listens for the change of the active station on the MapsStyler and "expands" the appropriate
   * LI-element
   */
  void _setup_stations(List<Station> station_list) {
    element.children.clear();
    station_list.forEach(_setup_station);
    mapsStyler.onActiveChange.listen((Station station) {
      if (station == null) {
        _hide_departures();
      } else {
        _show_departures(station);
      }
    });
  }

  /**
   * Sets up a the station LI-element with appropriate listeners and UL-element of departures.
   */
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
    element.append(li);
  }

  /**
   * Toggles the active station on the MapStyler
   */
  _toggle_departure(Station station) {
    if (mapsStyler.active == station) {
      mapsStyler.active = null;
    } else {
      mapsStyler.active = station;
    }

  }

  /**
   * Hide the departures of the internal _active_station
   */
  void _hide_departures() {
    _station_li_map[_active_station].classes.remove('active');
  }

  /**
   * Show the departures of a given station
   * It does not change the active station on the MapsStyler, but updates the internal active station: _active_station
   */
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

  /**
   * Creates a LI from a given departure.
   */
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

  /**
   * Enables updating of the station.
   */
  void _show_update(Station station) {
    _station_li_map[station].classes.add('updateable');
  }

  /**
   * Registers a function to be called every minute, ideal for updating departure-time.
   */
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

/**
 * Adds classes to given element from a MapStyler
 */
class MapsClassStyler extends Styler {

  final MapsStyler mapStyler;

  MapsClassStyler(Element element, this.mapStyler) : super(element);

  /**
   * Initially adds initialzing class
   * When has-location adds has_location class
   * When the map-view is changed the classes are removed
   */
  setup() {

    element.classes.add('initializing');
    mapStyler.onHasLocation.listen((_) {
      element.classes.add('has_location');
    });

    mapStyler.onStationViewChange.listen((_) {
      element.classes
        ..remove('initializing')
        ..remove('has_location');
    });

  }


}

/**
 * The MapsStyler 'styles' an element by creating a (google) map in it.
 * The map will contain markers modeling the stations and an active station.
 */
class MapsStyler extends Styler {

  Maps.GMap _map_instance;
  Maps.Circle _location_circle;
  int _min_accuracy = 700;
  StreamController<int> _min_accuracy_controller = new StreamController.broadcast();
  StreamController<Position> _on_has_location_controller = new StreamController.broadcast();
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

  Stream<Station> get onActiveChange => _on_active_change_controller.stream;
  Stream<List<Station>> get onStationViewChange => _station_view_controller.stream;
  Stream<Position> get onHasLocation => _on_has_location_controller.stream;

  Station get active => _active;

  set active(Station value) {
    _active = value;
    _on_active_change_controller.add(value);
  }

  set min_accuracy(int value) => _min_accuracy_controller.add(_min_accuracy = value);

  get min_accuracy => _min_accuracy;

  MapsStyler(Element element) : super(element);

  /**
   * Sets up the map
   * If no location is provided through the location hash the location is found with geolocation
   * If that fails the current location is set to my home
   */
  setup() async {
    var location;
    if ((location = _hash_position) == null) {
      try {
        var position = await window.navigator.geolocation.getCurrentPosition(enableHighAccuracy:true);
        location = new Position.fromNum(position.coords.latitude, position.coords.longitude, position.coords.accuracy);
      } catch (e) {
        location = new Position(56189776, 10219774, 700);
      }

    }
    window.onHashChange.listen((_) => showMapAt(_hash_position));
    _on_has_location_controller.add(location);
    showMapAt(location);
    _min_accuracy_controller.stream.listen((int accuracy) => showMapAt(location.changeAccuracy(accuracy)));
  }


  /**
   * Gets the position from the location hash
   * If the hash isn't on right format, null is returned
   */
  Position get _hash_position {
    var match = new RegExp(r"^#([0-9]+)/([0-9]+)/([0-9]+)$").firstMatch(window.location.hash);
    if (match == null) {
      return null;

    }
    return new Position(int.parse(match.group(1)), int.parse(match.group(2)), int.parse(match.group(3)));
  }

  /**
   * Centers the map and shows nearby stations to the provided position.
   */
  showMapAt(Position position) async {
    if (position == null) {
      return;
    }
    position = position.changeAccuracy(max(position.accuracy, _min_accuracy));
    var station_list = await stationsNearby(position, position.accuracy);
    _map.center = position.latlng;
    _draw_location(position);
    _draw_stations(station_list);
    onActiveChange.listen(_setup_marker);

  }

  /**
   * Draw a list of stations on the map, all stations in the map, but not in the list, are removed
   */
  _draw_stations(List<Station> station_list) {
    _station_marker_map.forEach((station, Maps.Marker marker) => marker.map = null);
    _station_view_controller.add(station_list);
    station_list.forEach(_draw_station);

  }

  /**
   * Draws a station on the map
   */
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

  /**
   * Draws the current location
   */
  void _draw_location(Position position) {

    if (_location_circle == null) {
      var circleOptions = new Maps.CircleOptions()
        ..strokeWeight = 0
        ..fillOpacity = 0.1
        ..fillColor = "#76cbe3"
        ..clickable = false
        ..map = _map;
      _location_circle = new Maps.Circle(circleOptions);
    }
    _location_circle
      ..radius = position.accuracy
      ..center = position.latlng;


  }

  /**
   * Sets the marker and adds a listener for changes
   */
  void _setup_marker(Station station) {
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
