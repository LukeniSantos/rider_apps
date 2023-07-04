import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:rider_apps/AllScreens/aboutScreen.dart';
import 'package:rider_apps/AllScreens/registrarscreen.dart';
import 'package:rider_apps/AllScreens/loginscreen.dart';
import 'package:rider_apps/AllScreens/mainscreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rider_apps/DataHandler/appData.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
DatabaseReference driverRef = FirebaseDatabase.instance.ref().child("drivers");
DatabaseReference newRequestsRef =
    FirebaseDatabase.instance.ref().child("Ride Requests");

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        title: 'Taxi Rider App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null
            ? LoginScreen.idScreen
            : MainScreen.idScreen,
        routes: {
          RegistrarScreen.idScreen: (context) => RegistrarScreen(),
          LoginScreen.idScreen: (context) => LoginScreen(),
          MainScreen.idScreen: (context) => MainScreen(),
          AboutScreen.idScreen: (context) => AboutScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
