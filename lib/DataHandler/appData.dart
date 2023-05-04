import 'package:flutter/cupertino.dart';
import 'package:rider_apps/Models/address.dart';

class AppData extends ChangeNotifier {
  Address pickUpLocation = Address();
  Address dropOfflocation = Address();

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropOfflocation = dropOffAddress;
    notifyListeners();
  }
}
