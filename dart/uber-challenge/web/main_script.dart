import "dart:html";

main() {
  window.navigator.geolocation.getCurrentPosition().then((Geoposition position) {
    print([position.coords.latitude, position.coords.longitude]);
  }, onError:(PositionError error) {
    print([error.code, error.message]);
  });
}