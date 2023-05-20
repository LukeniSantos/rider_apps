import 'package:flutter/cupertino.dart';
import 'package:rider_apps/Models/address.dart';

class AppData extends ChangeNotifier {
  Address pickUpLocation = Address();
  Address dropOffLocation = Address();

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropOffLocation = dropOffAddress;
    notifyListeners();
  }
}
