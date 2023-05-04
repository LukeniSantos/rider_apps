// ignore_for_file: empty_constructor_bodies

class Address {
  // ignore: prefer_typing_uninitialized_variables
  var placeFormattedAddress;
  var placeName;
  var placeId;
  var latitude;
  var longitude;

  Address(
      {this.placeFormattedAddress,
      this.placeName,
      this.placeId,
      this.latitude,
      this.longitude});
}
