import 'package:flutter/cupertino.dart';
import 'package:rider_apps/Models/address.dart';

import '../Models/history.dart';

class AppData extends ChangeNotifier {
  Address pickUpLocation = Address();
  Address dropOfflocation = Address();

  String earnings = "0";
  int countTrips = 0;
  List<String> tripHistoryKeys = [];
  List<History> tripHistoryDataList = [];

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropOfflocation = dropOffAddress;
    notifyListeners();
  }

  void updateEarnings(String updateEarnings) {
    earnings = updateEarnings;
    notifyListeners();
  }

  void updateTripsCounter(int tripCounter) {
    countTrips = tripCounter;
    notifyListeners();
  }

  void updateTripKeys(List<String> newKeys) {
    tripHistoryKeys = newKeys;
    notifyListeners();
  }

  void updateTripHistoryData(History eachHistory) {
    tripHistoryDataList.add(eachHistory);
    notifyListeners();
  }
}
