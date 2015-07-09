import 'dart:html';
import "package:uber_challenge/lib.dart";

main() {

  var maps_styler = new MapsStyler(querySelector("#MapCanvas"));
  maps_styler.setup();
  var time_table_styler = new TimeTableStyler(querySelector('#Timetable'), maps_styler);
  time_table_styler.setup();
}
