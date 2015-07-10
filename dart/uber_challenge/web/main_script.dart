import 'dart:html';
import "package:uber_challenge/lib.dart";

main() {

  var maps_styler = new MapsStyler(querySelector("#MapCanvas"));
  maps_styler.setup();
  new MapsClassStyler(querySelector('body'), maps_styler).setup();
  new TimeTableStyler(querySelector('#Timetable'), maps_styler).setup();
}
