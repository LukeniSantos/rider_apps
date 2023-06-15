import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rider_apps/Models/allUsers.dart';

String mapKey = "AIzaSyCuBH7uNOGkVhFpKbmuIRIlxoK_82T6JOk";

var firebaseUser;

Users userCurrentInfo = Users();

int driverRequestTimeOut = 40;
String statusRide = "";
String rideStatus = "Driver is Coming";

String carDetailsDriver = "";
String driverName = "";
String driverPhone = "";

double starCounter = 0.0;
String title = "";

String serverToken =
    "key=AAAAw54mHo8:APA91bF1cxjmBInBl3L58ZT5X9bX9niIyNGKTdsVHMGwdV7teaYGqe8Mqy6wXl1-pGr4BTI-d1114tYYoNiCDQGRG-ZPwkcilgeUjpoDA-PqPHzGa0-togKYwmknWHR4AOsAqMtrnn5q";
