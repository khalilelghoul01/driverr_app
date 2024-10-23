import 'dart:async';
import 'dart:developer';
import 'package:drivers_app/assistants/geofire.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/models/direction_details_info.dart';
import 'package:drivers_app/widgets/TrajetButton.dart';
import 'package:drivers_app/widgets/fare_amount_collection_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../InfoHandler/app_info.dart';
import '../assistants/assistant_methods.dart';

import '../models/ride_request_information.dart';
import '../widgets/progress_dialog.dart';
import '../widgets/user_cancel_message_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class NewTripScreen extends StatefulWidget {
  RideRequestInformation? rideRequestInformation;

  NewTripScreen({super.key, this.rideRequestInformation});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  GoogleMapController? newTripMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(36.891696, 10.1815426),
    zoom: 14.4746,
  );

  Set<Marker> setOfMarkers = <Marker>{};
  Set<Circle> setOfCircles = <Circle>{};
  Set<Polyline> polyLineSet = <Polyline>{};
  List<LatLng> polyLineCoordinatesList = [];
  PolylinePoints polylinePoints = PolylinePoints();

  double mapPadding = 0;
  var geoLocator = Geolocator();
  BitmapDescriptor? driverIconMarker;

  Position? driverLiveLocation;

  String rideRequestStatus = "Accepted";
  String buttonTitle = "Arrivé";
  Color buttonColor = Colors.green;
  String durationFromSourceToDestination = "";

  bool isRequestDirectionDetails = false;
  bool dialogDisplayed = false;

  // When driver accepts ride request, sourceLatLng = driver Current Location, destinationLatLng = driver pickup Location
  // When driver starts the ride, sourceLatLng = User Current Location, destinationLatLng = User Dropoff Location
  void callUser() async {
    final phoneNumber = widget.rideRequestInformation!
        .userPhone; // Assure-toi que ce champ est défini dans tes données de trajet
    Uri url = Uri(scheme: "tel", path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("Can't open dial pad.");
    }
  }

  Future<void> drawPolylineFromSourceToDestination(
      LatLng sourceLatLng, LatLng destinationLatLng) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: AppLocalizations.of(context)!.processingPleasewait,
            ));

    var directionDetailsInfo =
        await AssistantMethods.getOriginToDestinationDirectionDetails(
            sourceLatLng, destinationLatLng);

    Navigator.pop(context);

    print(directionDetailsInfo!.e_points);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsList =
        polylinePoints.decodePolyline(directionDetailsInfo.e_points!);

    polyLineCoordinatesList.clear();

    if (decodedPolyLinePointsList.isNotEmpty) {
      for (var pointLatLng in decodedPolyLinePointsList) {
        polyLineCoordinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.black,
        polylineId: const PolylineId("PolyLineID"),
        jointType: JointType.bevel,
        points: polyLineCoordinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.squareCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if (sourceLatLng.latitude > destinationLatLng.latitude &&
        sourceLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: sourceLatLng);
    } else if (sourceLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(sourceLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, sourceLatLng.longitude),
      );
    } else if (sourceLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, sourceLatLng.longitude),
        northeast: LatLng(sourceLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: sourceLatLng, northeast: destinationLatLng);
    }

    newTripMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: const MarkerId("sourceID"),
      position: sourceLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      setOfMarkers.add(originMarker);
      setOfMarkers.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.black,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: sourceLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.black,
      radius: 12,
      strokeWidth: 15,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      setOfCircles.add(originCircle);
      setOfCircles.add(destinationCircle);
    });
  }

  void updateEarningsBasedOnTime() async {
    DateTime now = DateTime.now();
    double? fareAmount = await AssistantMethods.getFareAmount(
        widget.rideRequestInformation!.rideRequestId);

    // Ajout des logs pour déboguer
    print("Current Time: $now");

    FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentFirebaseUser!.uid)
        .once()
        .then((snapData) {
      DataSnapshot snapshot = snapData.snapshot;

      double previousTotalEarnings = 0.0;
      double previousTodayEarnings = 0.0;
      double previousMonthEarnings = 0.0;
      int tripCount = 0;

      DateTime? lastEarningsUpdate;
      DateTime? lastMonthUpdate;

      // Récupérer les valeurs précédentes si elles existent
      if (snapshot.child("totalEarnings").exists) {
        previousTotalEarnings =
            double.parse(snapshot.child("totalEarnings").value.toString());
      }
      if (snapshot.child("todayEarnings").exists) {
        previousTodayEarnings =
            double.parse(snapshot.child("todayEarnings").value.toString());
      }
      if (snapshot.child("monthEarnings").exists) {
        previousMonthEarnings =
            double.parse(snapshot.child("monthEarnings").value.toString());
      }
      if (snapshot.child("tripCount").exists) {
        tripCount = int.parse(snapshot.child("tripCount").value.toString());
      }
      if (snapshot.child("lastEarningsUpdate").exists) {
        lastEarningsUpdate = DateTime.parse(
            snapshot.child("lastEarningsUpdate").value.toString());
      }
      if (snapshot.child("lastMonthUpdate").exists) {
        lastMonthUpdate =
            DateTime.parse(snapshot.child("lastMonthUpdate").value.toString());
      }

      // Vérifier si la date a changé depuis la dernière mise à jour des gains journaliers
      if (lastEarningsUpdate == null || lastEarningsUpdate.day != now.day) {
        previousTodayEarnings = 0.0; // Réinitialiser les gains d'aujourd'hui
      }

      // Vérifier si le mois a changé depuis la dernière mise à jour des gains mensuels
      if (lastMonthUpdate == null || lastMonthUpdate.month != now.month) {
        previousMonthEarnings = 0.0; // Réinitialiser les gains mensuels
      }

      // Calculer les nouveaux gains
      double newTotalEarnings = previousTotalEarnings + fareAmount!;
      double newTodayEarnings = previousTodayEarnings + fareAmount;
      double newMonthEarnings = previousMonthEarnings + fareAmount;
      tripCount += 1;

      // Mettre à jour Firebase avec les nouveaux gains et les dates de dernière mise à jour
      FirebaseDatabase.instance
          .ref()
          .child("Drivers")
          .child(currentFirebaseUser!.uid)
          .update({
        "totalEarnings": newTotalEarnings.toString(),
        "todayEarnings": newTodayEarnings.toString(),
        "monthEarnings": newMonthEarnings.toString(),
        "tripCount": tripCount,
        "lastTripFare": fareAmount,
        "lastEarningsUpdate": now
            .toIso8601String(), // Stocker la dernière mise à jour des gains journaliers
        "lastMonthUpdate": now
            .toIso8601String(), // Stocker la dernière mise à jour des gains mensuels
      });
    });
  }

  endTrip() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
              message: AppLocalizations.of(context)!.processingPleasewait);
        });

// double lat=35.2365755 ;
// double long=11.1129606 ;
// var currentDriverPositionLatLng = LatLng(lat, long);
//  //  Get Trip direction details - Distance and duration travelled
//    var tripDirectionDetailsInfo = await AssistantMethods.getOriginToDestinationDirectionDetails(
//        currentDriverPositionLatLng,
//        widget.rideRequestInformation!.sourceLatLng!
//     );

    //Fluttertoast.showToast(msg: "KM:" + tripDirectionDetailsInfo!.duration_text! + " Time:" + tripDirectionDetailsInfo.distance_text!);

    // Fare Amount
    double? fareAmount = await AssistantMethods.getFareAmount(
        widget.rideRequestInformation!.rideRequestId);

    FirebaseDatabase.instance
        .ref()
        .child("AllRideRequests")
        .child(widget.rideRequestInformation!.rideRequestId!)
        .child("status")
        .set("Ended");
    // FirebaseDatabase.instance.ref()
    //     .child("AllRideRequests")
    //     .child(widget.rideRequestInformation!.rideRequestId!)
    //     .child("fareAmount")
    //     .set(fareAmount);

    streamSubscriptionPosition!.cancel();

    Navigator.pop(context);

    // Display Fare amount dialogbox
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return FareAmountDialog(
              fareAmount: fareAmount.toStringAsFixed(1),
              userName: widget.rideRequestInformation!.userName);
        });

    // Store current earning to total earnings in database
//    FirebaseDatabase.instance.ref()
//     .child("Drivers")
//     .child(currentFirebaseUser!.uid)
//     .once()
//     .then((snapData) {
//   DataSnapshot snapshot = snapData.snapshot;

//   // Si le nœud "Drivers" existe
//   if (snapshot.exists) {
//     double previousTotalEarnings = 0.0;
//     double previousTodayEarnings = 0.0;
//     double previousWeekEarnings = 0.0;
//     double previousMonthEarnings = 0.0;

//     // Récupérer les valeurs précédentes si elles existent
//     if (snapshot.child("totalEarnings").exists) {
//       previousTotalEarnings = double.parse(snapshot.child("totalEarnings").value.toString());
//     }
//     if (snapshot.child("todayEarnings").exists) {
//       previousTodayEarnings = double.parse(snapshot.child("todayEarnings").value.toString());
//     }
//     if (snapshot.child("weekEarnings").exists) {
//       previousWeekEarnings = double.parse(snapshot.child("weekEarnings").value.toString());
//     }
//     if (snapshot.child("monthEarnings").exists) {
//       previousMonthEarnings = double.parse(snapshot.child("monthEarnings").value.toString());
//     }

//     // Calculer les nouveaux gains
//     double newTotalEarnings = previousTotalEarnings + fareAmount;
//     double newTodayEarnings = previousTodayEarnings + fareAmount;
//     double newWeekEarnings = previousWeekEarnings + fareAmount;
//     double newMonthEarnings = previousMonthEarnings + fareAmount;

//     // Mettre à jour Firebase avec les nouveaux gains
//     FirebaseDatabase.instance.ref()
//         .child("Drivers")
//         .child(currentFirebaseUser!.uid)
//         .update({
//       "totalEarnings": newTotalEarnings.toString(),
//       "todayEarnings": newTodayEarnings.toString(),
//       "weekEarnings": newWeekEarnings.toString(),
//       "monthEarnings": newMonthEarnings.toString(),
//     });
//   } else {
//     // Si le nœud "Drivers" n'existe pas encore, initialiser les gains
//     FirebaseDatabase.instance.ref()
//         .child("Drivers")
//         .child(currentFirebaseUser!.uid)
//         .set({
//       "totalEarnings": fareAmount.toString(),
//       "todayEarnings": fareAmount.toString(),
//       "weekEarnings": fareAmount.toString(),
//       "monthEarnings": fareAmount.toString(),
//     });
//   }
// });
  }

  @override
  void initState() {
    super.initState();

    saveAssignedDriverDetailsToRideRequest();
  }

  driverIsOnlineNow() async {
    driverCurrentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    Geofire.initialize(
        "ActiveDrivers"); // Setting up a new node in realtime database
    Geofire.setLocation(currentFirebaseUser!.uid,
        driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

    DatabaseReference reference = FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    reference.set("Idle");
    reference.onValue.listen((event) {});
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("AllRideRequests")
        .child(widget.rideRequestInformation!.rideRequestId!)
        .child("status");

    Stream<DatabaseEvent> stream = ref.onValue;
    stream.listen((DatabaseEvent event) {
      print('Event Type: ${event.type}');
      print('Snapshot: ${event.snapshot.value}');
      rideRequestStatus = event.snapshot.value.toString();

      if (rideRequestStatus == "Cancelled" && !dialogDisplayed) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            dialogDisplayed = true;
            return const UserCancelMessageDialog();
          },
        );
      }
    });

    createActiveDriverIconMarker();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: mapPadding),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              markers: setOfMarkers,
              circles: setOfCircles,
              polylines: polyLineSet,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newTripMapController = controller;

                setState(() {
                  mapPadding = 320;
                });

                var driverCurrentLatLng = LatLng(
                    driverCurrentPosition!.latitude,
                    driverCurrentPosition!.longitude);
                var userCurrentLatLng =
                    widget.rideRequestInformation!.sourceLatLng;

                drawPolylineFromSourceToDestination(
                    driverCurrentLatLng, userCurrentLatLng!);
                updateDriversLocationAtRealTime();
                print("before ...");
                updateDurationAtRealTime(driverCurrentLatLng);
                print("After.....");
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration:
                    const BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 10,
                    spreadRadius: 0.5,
                    offset: Offset(0.6, 0.6),
                  )
                ]),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        durationFromSourceToDestination,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(
                        thickness: 2,
                        height: 2,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            widget.rideRequestInformation!.userName!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.phone_android,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Image.asset(
                            "images/source.png",
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.rideRequestInformation!.sourceAddress!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Image.asset(
                            "images/destination.png",
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget
                                  .rideRequestInformation!.destinationAddress!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Divider(
                        thickness: 2,
                        height: 2,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 20),

                      // Aligning the buttons side by side
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Button for Ride Request Status (Accepted, Arrived, etc.)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (rideRequestStatus == "Accepted") {
                                  rideRequestStatus = "Arrived";
                                  updateEarningsBasedOnTime();
                                  setState(() {
                                    buttonTitle = "Démarrer le trajet";
                                    buttonColor = Colors.green;
                                  });
                                  FirebaseDatabase.instance
                                      .ref()
                                      .child("AllRideRequests")
                                      .child(widget.rideRequestInformation!
                                          .rideRequestId!)
                                      .child("status")
                                      .set(rideRequestStatus);

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return ProgressDialog(message: "Loading");
                                    },
                                  );

                                  await drawPolylineFromSourceToDestination(
                                    widget
                                        .rideRequestInformation!.sourceLatLng!,
                                    widget.rideRequestInformation!
                                        .destinationLatLng!,
                                  );

                                  Navigator.pop(context);
                                } else if (rideRequestStatus == "Arrived") {
                                  rideRequestStatus = "On Trip";
                                  setState(() {
                                    buttonTitle = "Trajet Fini";
                                    buttonColor = Colors.redAccent;
                                  });
                                  FirebaseDatabase.instance
                                      .ref()
                                      .child("AllRideRequests")
                                      .child(widget.rideRequestInformation!
                                          .rideRequestId!)
                                      .child("status")
                                      .set(rideRequestStatus);
                                } else if (rideRequestStatus == "On Trip") {
                                  endTrip();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                              ),
                              icon: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 25,
                              ),
                              label: Text(
                                buttonTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Button for Opening Google Maps with Navigation
                          Expanded(
                            child: TrajetButton(
                              statut: rideRequestStatus, // Le statut mis à jour
                              driverLat: driverCurrentPosition!.latitude,
                              driverLng: driverCurrentPosition!.longitude,
                              sourceLat: widget.rideRequestInformation!
                                  .sourceLatLng!.latitude,
                              sourceLng: widget.rideRequestInformation!
                                  .sourceLatLng!.longitude,
                              destinationLat: widget.rideRequestInformation!
                                  .destinationLatLng!.latitude,
                              destinationLng: widget.rideRequestInformation!
                                  .destinationLatLng!.longitude,
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
      ),
    );
  }

  // Save All information about driver in Ride Request section of database
  saveAssignedDriverDetailsToRideRequest() {
    DatabaseReference reference = FirebaseDatabase.instance
        .ref()
        .child("AllRideRequests")
        .child(widget.rideRequestInformation!.rideRequestId!);

    Map driverCarDetailsMap = {
      //"carColor" : driverData.carColor,
      "carModel": driverData.carModel,
      "carNumber": driverData.carNumber,
      // "carType" : driverData.carType
    };

    Map driverLocationDataMap = {
      "latitude": driverCurrentPosition!.latitude,
      "longitude": driverCurrentPosition!.longitude,
    };
    final currentUserId = currentFirebaseUser!.uid;
    reference.child("status").set("Accepted");
    reference.child("driverId").set(currentUserId);
    print("driverdataID${driverData.id}");
    reference.child("driverName").set(driverData.name);
    reference.child("driverPhone").set(driverData.phone);
    reference.child("carDetails").set(driverCarDetailsMap);
    reference
        .child("driverLocationData")
        .child("latitude")
        .set(double.tryParse(driverCurrentPosition!.latitude.toString()));
    reference
        .child("driverLocationData")
        .child("longitude")
        .set(double.tryParse(driverCurrentPosition!.longitude.toString()));
    reference.child("driverPhoto").set(driverData.photoUrl);

    // Save Ride request id to driver's history
    saveRideRequestId();
  }

  saveRideRequestId() {
    DatabaseReference reference = FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentFirebaseUser!.uid)
        .child("tripHistory");

    reference.child(widget.rideRequestInformation!.rideRequestId!).set(true);
  }

  createActiveDriverIconMarker() {
    if (driverIconMarker == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car-2.png")
          .then((value) {
        driverIconMarker = value;
      });
    }
  }

  updateDriversLocationAtRealTime() {
    // Fluttertoast.showToast(msg: "Inside updateDriversLocationAtRealTime()");
    streamSubscriptionPosition =
        Geolocator.getPositionStream() // Get Updated position of the driver
            .listen((Position position) {
      driverCurrentPosition = position;
      driverLiveLocation = position;

      LatLng driverLivePositionLatLng = LatLng(
        driverLiveLocation!.latitude,
        driverLiveLocation!.longitude,
      );

      Marker animatingCarMarker = Marker(
          markerId: const MarkerId("animatingCarMarker"),
          position: driverLivePositionLatLng,
          icon: driverIconMarker!);

      setState(() {
        CameraPosition cameraPosition = CameraPosition(
            target: driverLivePositionLatLng,
            zoom: 16); // New CameraPosition everytime the location is updated
        newTripMapController!.animateCamera(CameraUpdate.newCameraPosition(
            cameraPosition)); // Animating camera in google map according to LatLng

        setOfMarkers.removeWhere(
            (element) => element.markerId.value == "animatingCarMarker");
        setOfMarkers.add(animatingCarMarker);
      });
//print("before function :....");

      Map driverUpdatedLocationMap = {
        "latitude": driverLiveLocation!.latitude.toString(),
        "longitude": driverLiveLocation!.longitude.toString(),
      };

      // Updating live location of the driver in realtime database
      FirebaseDatabase.instance
          .ref()
          .child("AllRideRequests")
          .child(widget.rideRequestInformation!.rideRequestId!)
          .child("driverLocationData")
          .set(driverUpdatedLocationMap);
    });
  }

  updateDurationAtRealTime(LatLng driver) async {
    // Fluttertoast.showToast(msg: "Inside updateDurationAtRealTime()");
    if (isRequestDirectionDetails == false) {
      isRequestDirectionDetails = true;

      if (driver == null) {
        return;
      }

      // Driver Current Position
      var destinationLatLng;

      if (rideRequestStatus == "Accepted") {
        destinationLatLng =
            widget.rideRequestInformation!.sourceLatLng; // User Pickup Address
      } else {
        destinationLatLng = widget
            .rideRequestInformation!.destinationLatLng; // User Dropoff Address
      }
      DirectionDetailsInfo? directionDetailsInfo = DirectionDetailsInfo();

      log("before function :$durationFromSourceToDestination");
      directionDetailsInfo =
          await AssistantMethods.getOriginToDestinationDirectionDetails(
              driver, destinationLatLng);
      durationFromSourceToDestination = directionDetailsInfo.duration_text!;

      log("After function ${directionDetailsInfo.duration_text!}");

      print("After functin ....$durationFromSourceToDestination");

      isRequestDirectionDetails = false;
    }
  }
}
