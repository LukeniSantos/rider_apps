import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_apps/AllScreens/HistoryScreen.dart';
import 'package:rider_apps/AllScreens/loginscreen.dart';
import 'package:rider_apps/AllScreens/profileTabPage.dart';
import 'package:rider_apps/AllScreens/ratingScreen.dart';
import 'package:rider_apps/AllScreens/registrarscreen.dart';
import 'package:rider_apps/AllScreens/searchScreen.dart';
import 'package:rider_apps/AllWidgets/Divider.dart';
import 'package:rider_apps/AllWidgets/collectFareDialog.dart';
import 'package:rider_apps/AllWidgets/noDriverAvailableDialog.dart';
import 'package:rider_apps/AllWidgets/progressDialog.dart';
import 'package:rider_apps/Assistants/AssistantMethods.dart';
import 'package:rider_apps/Assistants/geoFireAssistant.dart';
import 'package:rider_apps/DataHandler/appData.dart';
import 'package:rider_apps/Models/directDetails.dart';
import 'package:rider_apps/Models/nearbyAvailableDrivers.dart';
import 'package:rider_apps/configMaps.dart';
import 'package:rider_apps/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'aboutScreen.dart';

/**
   * Texte começa aqui 
   */
Future<Position> _getcurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error("serviço desabilitado");
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error("Permissão está negada mesmo");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error("Está negado pra toda vida");
  }
  return await Geolocator.getCurrentPosition();
}

/**
   * Texte Termina aqui 
   */

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}

const colorizeColors = [
  Colors.black,
  Colors.white,
  Colors.black,
];

const colorizeTextStyle = TextStyle(
  fontSize: 55.0,
  fontFamily: 'Signatra',
);

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails = new DirectionDetails();

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  var geoLocator = Geolocator();
  double bottonPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double driverDetailsContainerHeight = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference? rideRequestRef;

  BitmapDescriptor? nearByIcon;

  List<NearbyAvailableDrivers>? availableDrivers;

  String state = "normal";

  StreamSubscription<DatabaseEvent>? rideStreamSubscription;

  bool isRequestingPositionDetails = false;

  String uName = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.ref().child("Ride Request").push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOfflocation;
    Map pickUpLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
      "ride_type": carRideType,
    };

    rideRequestRef!.set(rideInfoMap);

    rideStreamSubscription = rideRequestRef?.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }
      Map data = event.snapshot.value as Map;

      if (data['car_details'] != null) {
        setState(() {
          carDetailsDriver = data['car_details'].toString();
        });
      }

      if (data['driver_name'] != null) {
        setState(() {
          driverName = data['driver_name'].toString();
        });
      }

      if (data['driver_phone'] != null) {
        setState(() {
          driverPhone = data['driver_phone'].toString();
        });
      }

      if (data['driver_location'] != null) {
        double driverLat =
            double.parse(data['driver_location']["latitude"].toString());
        double driverLng =
            double.parse(data['driver_location']["longitude"].toString());
        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

        if (statusRide == "accepted") {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        } else if (statusRide == "onride") {
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        } else if (statusRide == "arrived") {
          setState(() {
            rideStatus = "Driver has Arrived.";
          });
        }
      }

      if (data['status'] != null) {
        statusRide = data['status'].toString();
      }

      if (statusRide == "accepted") {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofileMakers();
      }

      if (statusRide == "ended") {
        if (data["fares"] != null) {
          int fare = int.parse(data["fares"].toString());
          var res = await showDialog(
            context: context,
            builder: (BuildContext context) => CollectFareDialog(
              paymentMethod: "cash",
              fareAmount: fare,
            ),
          );
          String driverId = "";
          if (res == "close") {
            if (data['driver_id'] != null) {
              driverId = data['driver_id'].toString();
            }

            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RatingScreen(driverId: driverId)));

            rideRequestRef!.onDisconnect();
            rideRequestRef = null;
            rideStreamSubscription!.cancel();
            rideStreamSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void deleteGeofileMakers() {
    setState(() {
      markersSet
          .removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var positionUserLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      var details = await AssistantMethods.obtainPlaceDirectionDetails(
          driverCurrentLocation, positionUserLatLng);

      if (details == null) {
        return;
      }

      setState(() {
        rideStatus = "Condutor a caminho " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var dropOff =
          Provider.of<AppData>(context, listen: false).dropOfflocation;
      var dropOffLatLng = LatLng(dropOff.latitude, dropOff.longitude);
      var details = await AssistantMethods.obtainPlaceDirectionDetails(
          driverCurrentLocation, dropOffLatLng);

      if (details == null) {
        return;
      }

      setState(() {
        rideStatus = "Condutor a caminho " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void cancelRideResquest() {
    rideRequestRef!.remove();
    setState(() {
      state = "normal";
    });
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottonPaddingOfMap = 230.0;
      drawerOpen = true;
    });
    saveRideRequest();
  }

  void displayDriverDetailsContainer() {
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0;
      bottonPaddingOfMap = 280.0;
      driverDetailsContainerHeight = 310.0;
    });
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0.0;
      requestRideContainerHeight = 0.0;
      bottonPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();

      statusRide = "";
      driverName = "";
      driverPhone = "";
      carDetailsDriver = "";
      rideStatus = "Condutor a caminho ";
      driverDetailsContainerHeight = 0.0;
    });
    locatePosition();
  }

  void displatrideDetailsContainerHeight() async {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240.0;
      bottonPaddingOfMap = 360.0;
      drawerOpen = false;
    });
  }

  var currentPosition;

  void locatePosition() async {
    _getcurrentLocation();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLatPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLatPosition, zoom: 16);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String adress =
        await AssistantMethods.searchCoordinateAdress(position, context);
    print("This is your Adress:: " + adress);

    initGeoFireListner();
    uName = userCurrentInfo.name;

    AssistantMethods.retrieveHistoryInfo(context);
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-8.838333, 13.234444),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            //Drawer header
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(width: 16.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            uName,
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfileTabPage()));
                            },
                            child: Text("Ver Perfil"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(height: 12.0),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()));
                },
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text(
                    "Historico",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfileTabPage()));
                  },
                  child: Text("Ver Perfil", style: TextStyle(fontSize: 15.0)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AboutScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    "Sobre",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(
                    "Sair",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottonPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottonPaddingOfMap = 300.0;
              });
              locatePosition();
            },
          ),

          //HamburgeerButton for Drawer
          Positioned(
            top: 30.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState!.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen ? Icons.menu : Icons.close),
                      color: Colors.black),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //Search ui
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),
                      Text(
                        "Ola",
                        style: TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        "Vamos!?",
                        style:
                            TextStyle(fontSize: 20.0, fontFamily: "Brand-Bold"),
                      ),
                      SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));

                          if (res == "Direção Obtida") {
                            displatrideDetailsContainerHeight();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(children: [
                              Icon(
                                Icons.search,
                                color: Colors.blueAccent,
                              ),
                              SizedBox(width: 10.0),
                              Text("Pesquisar Local De Destino")
                            ]),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0),
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Provider.of<AppData>(context)
                                          .pickUpLocation !=
                                      null
                                  ? Provider.of<AppData>(context)
                                      .pickUpLocation
                                      .placeName
                                      .toString()
                                  : "Ad Home"),
                              SizedBox(height: 4.0),
                              Text(
                                "Localização atual",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      DividerWidget(),
                      SizedBox(
                        height: 16.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Local do serviço"),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                "Your Living Office adress",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          //ride details
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      //bike Motos
                      GestureDetector(
                        onTap: () {
                          displayToastMesenger("Procurando moto..", context);
                          setState(() {
                            state = "requesting";
                            carRideType = "bike";
                          });
                          displayRequestRideContainer();
                          availableDrivers =
                              GeoFireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/bike.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(width: 16.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Motorizada",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold"),
                                    ),
                                    Text(
                                      ((tripDirectionDetails.distanceText !=
                                              null)
                                          ? tripDirectionDetails.distanceText
                                          : ""),
                                      style: TextStyle(
                                          fontSize: 16.0, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails.distanceText != null)
                                      ? "${(AssistantMethods.calculateFares(tripDirectionDetails)) / 2}0kz"
                                      : ""),
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontFamily: "Brand Bold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Divider(height: 2.0, thickness: 2.0),
                      SizedBox(height: 10.0),
                      //
                      //uber go
                      GestureDetector(
                        onTap: () {
                          displayToastMesenger("Procurando carro...", context);
                          setState(() {
                            state = "requesting";
                            carRideType = "uber-go";
                          });
                          displayRequestRideContainer();
                          availableDrivers =
                              GeoFireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/ubergo.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(width: 16.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Carro",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold"),
                                    ),
                                    Text(
                                      ((tripDirectionDetails.distanceText !=
                                              null)
                                          ? tripDirectionDetails.distanceText
                                          : ""),
                                      style: TextStyle(
                                          fontSize: 16.0, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails.distanceText != null)
                                      ? "${AssistantMethods.calculateFares(tripDirectionDetails)}.00kz"
                                      : ""),
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontFamily: "Brand Bold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Divider(height: 2.0, thickness: 2.0),
                      SizedBox(height: 10.0),
                      //

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(children: [
                          Icon(FontAwesomeIcons.moneyCheckDollar,
                              size: 18.0, color: Colors.black54),
                          SizedBox(width: 16.0),
                          Text("Cash"),
                          SizedBox(width: 6.0),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black54,
                            size: 16.0,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //Cancel Ui
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    SizedBox(height: 12.0),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Solicitando corrida...',
                            textStyle: colorizeTextStyle,
                            textAlign: TextAlign.center,
                            colors: colorizeColors,
                          ),
                          ColorizeAnimatedText(
                            'Aguarde...',
                            textStyle: colorizeTextStyle,
                            textAlign: TextAlign.center,
                            colors: colorizeColors,
                          ),
                          ColorizeAnimatedText(
                            'Procurando Colega...',
                            textStyle: colorizeTextStyle,
                            textAlign: TextAlign.center,
                            colors: colorizeColors,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),
                    SizedBox(height: 22.0),
                    GestureDetector(
                      onTap: () {
                        cancelRideResquest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(
                              width: 2.0,
                              color: Color.fromRGBO(224, 224, 224, 1)),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 26.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 22.0),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cacelar viagem",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Display Assisned driver info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: driverDetailsContainerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 6.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(rideStatus,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20.0, fontFamily: "Brand Bold")),
                      ],
                    ),
                    SizedBox(height: 22.0),
                    Divider(height: 2.0, thickness: 2.0),
                    SizedBox(height: 22.0),
                    Text(
                      carDetailsDriver,
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      driverName,
                      style: TextStyle(fontSize: 20.0),
                    ),
                    SizedBox(height: 22.0),
                    Divider(height: 2.0, thickness: 2.0),
                    SizedBox(height: 22.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // call Button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.red),
                            ),
                            onPressed: () {
                              launchUrl(Uri.parse('tel://${driverPhone}'));
                            },
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "Ligar ao condutor",
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: 26.0,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var inicialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOfflocation;

    var pickUpLatLng = LatLng(inicialPos.latitude, inicialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Aguarde..."));

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);

    setState(() {
      if (details != null) {
        tripDirectionDetails = details;
      }
    });

    Navigator.pop(context);
    print("**Econding point ::");
    print(details!.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if (decodePolylinePointsResult.isNotEmpty) {
      decodePolylinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setState(() {
      Polyline polyline = Polyline(
          color: Colors.pink,
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow:
            InfoWindow(title: inicialPos.placeName, snippet: "my location"),
        position: pickUpLatLng,
        markerId: MarkerId("pickUpId"));

    Marker dropOffLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: "DropOff Location"),
        position: dropOffLatLng,
        markerId: MarkerId("dropOffId"));

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGeoFireListner() {
    //Comentario
    Geofire.initialize("availableDrivers");
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 15)!
        .listen((map) {
      print(map.toString());
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map["key"];
            nearbyAvailableDrivers.latitude = map["latitude"];
            nearbyAvailableDrivers.longitude = map["longitude"];
            GeoFireAssistant.nearbyAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map["key"]);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvaliableDrivers =
                NearbyAvailableDrivers();
            nearbyAvaliableDrivers.key = map["key"];
            nearbyAvaliableDrivers.latitude = map["latitude"];
            nearbyAvaliableDrivers.longitude = map["longitude"];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvaliableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});
    });
    //Comentario
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMarkers = Set<Marker>();
    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvaiablePosition = LatLng(driver.latitude, driver.longitude);
      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvaiablePosition,
        icon: nearByIcon!,
        //rotation: AssistantMethods.createRandomNumber(360),
      );

      tMarkers.add(marker);
    }

    setState(() {
      markersSet = tMarkers;
    });
  }

  void createIconMarker() {
    if (nearByIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(10, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_ios.png")
          .then((value) {
        nearByIcon = value;
      });
    }
  }

  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverAvailableDialog());
  }

  void searchNearestDriver() {
    if (availableDrivers!.length == 0) {
      cancelRideResquest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers![0];

    driverRef
        .child(driver.key)
        .child("car_details")
        .child("type")
        .once()
        .then((snap) async {
      if (await snap.snapshot.value != null) {
        String carType = snap.snapshot.value.toString();
        if (carType == carRideType) {
          notifyDriver(driver);
          availableDrivers!.removeAt(0);
        } else {
          displayToastMesenger(
              carRideType + " Condutor não disponivel. tente novamente",
              context);
        }
      } else {
        displayToastMesenger(
            "Nenhum carro encontrado. Tente novamente.", context);
      }
    });
  }

  void notifyDriver(NearbyAvailableDrivers driver) {
    driverRef.child(driver.key).child("newRide").set(rideRequestRef!.key);
    driverRef
        .child(driver.key)
        .child("token")
        .once()
        .then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        String token = event.snapshot.value.toString();
        AssistantMethods.sendNotificationToDriver(
            token, context, rideRequestRef!.key.toString());
      } else {
        return;
      }

      const oneSecondPassed = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecondPassed, (timer) {
        if (state != "requesting") {
          driverRef.child(driver.key).child("newRide").set("cancelled");
          driverRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();
        }
        driverRequestTimeOut--;

        driverRef.child(driver.key).child("newRide").onValue.listen((event) {
          print(event.snapshot.value.toString());
          if (event.snapshot.value.toString() == "accepted") {
            driverRef.child(driver.key).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }
        });

        if (driverRequestTimeOut == 0) {
          driverRef.child(driver.key).child("newRide").set("timeout");
          driverRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          searchNearestDriver();
        }
      });
    });
  }
}
