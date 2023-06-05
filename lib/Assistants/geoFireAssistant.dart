import 'package:rider_apps/Models/nearbyAvaliableDrivers.dart';

class GeoFireAssistant {
  static List<NearbyAvailableDrivers> nearbyAvaliableDriversList = [];
  static void removeDriverFromList(String key) {
    int index =
        nearbyAvaliableDriversList.indexWhere((element) => element.key == key);
    nearbyAvaliableDriversList.removeAt(index);
  }

  static void updateDriverNearbyLocation(NearbyAvailableDrivers driver) {
    int index = nearbyAvaliableDriversList
        .indexWhere((element) => element.key == driver.key);

    nearbyAvaliableDriversList[index].latitude = driver.latitude;
    nearbyAvaliableDriversList[index].longitude = driver.longitude;
  }
}
