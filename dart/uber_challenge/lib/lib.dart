library uber_challenge;
import "package:google_maps/google_maps.dart" as Maps;
import 'dart:async';
import 'dart:html';
import 'dart:convert';
import 'dart:math';

part "src/model.dart";
part "src/stylers.dart";


/**
 * Creates a string representation of a given duration
 * The string will be Soon, if the duration is less than a minute
 * {min} minute(s) if the duration is less than an hour
 * or {hour} hour(s) {min} minute(s) else
 */
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


/**
 * Creates a short name. E.g.
 * Bus 123 => 123
 * Bybus 42 => 42
 * RE 1234 => RE
 */
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
