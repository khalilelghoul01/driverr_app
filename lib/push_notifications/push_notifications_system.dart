import 'dart:developer';
import 'package:drivers_app/models/ride_request_information.dart';
import 'package:drivers_app/widgets/push_notification_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificationSystem {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isDialogShown = false;

  Future<void> initializeCloudMessaging(BuildContext context) async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('User granted provisional permission');
    } else {
      log('User declined or has not accepted permission');
      return;
    }

    // Handle incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Foreground notification received");
      retrieveRideRequestInformation(message.data["rideRequestId"], context);
    });

    // Handle notification when the app is in the background and is opened from the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("Background notification opened");
      retrieveRideRequestInformation(message.data["rideRequestId"], context);
    });

    // Handle notification when the app is terminated and is opened from the notification
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log("Terminated notification opened");
      retrieveRideRequestInformation(
          initialMessage.data["rideRequestId"], context);
    }

    // Generate and save FCM token
    await generateRegistrationToken();
  }

  Future<void> generateRegistrationToken() async {
    String? token = await _firebaseMessaging.getToken();
    log("FCM Registration Token: $token");

    FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("token")
        .set(token);

    _firebaseMessaging.subscribeToTopic("allDrivers");
    _firebaseMessaging.subscribeToTopic("allUsers");
  }

  void retrieveRideRequestInformation(
      String rideRequestID, BuildContext context) {
    if (_isDialogShown) {
      log("Dialog already shown. Ignoring this notification.");
      return;
    }

    FirebaseDatabase.instance
        .ref()
        .child("AllRideRequests")
        .child(rideRequestID)
        .once()
        .then((snapData) async {
      if (snapData.snapshot.value != null) {
        _isDialogShown = true;
        final snapshot = snapData.snapshot;
        if (snapshot.exists) {
          String? status =
              (snapData.snapshot.value! as Map)["status"].toString();

          // Check if the ride request has timed out, and if so, exit early
          if (status == "TimeOut") {
            log("Request timed out. Not displaying the notification.");
            return;
          }

          log("Request status: $status");
          // Extract ride request details for valid requests
          String rideRequestID = snapshot.key!;
          double sourceLat = double.parse(
              (snapData.snapshot.value! as Map)["source"]["latitude"]
                  .toString());
          double sourceLng = double.parse(
              (snapData.snapshot.value! as Map)["source"]["longitude"]
                  .toString());
          String sourceAddress =
              (snapData.snapshot.value! as Map)["sourceAddress"];
          double destinationLat = double.parse(
              (snapData.snapshot.value! as Map)["destination"]["latitude"]
                  .toString());
          double destinationLng = double.parse(
              (snapData.snapshot.value! as Map)["destination"]["longitude"]
                  .toString());
          String destinationAddress =
              (snapData.snapshot.value! as Map)["destinationAddress"];
          String userName = (snapData.snapshot.value! as Map)["userName"];
          String userPhone = (snapData.snapshot.value! as Map)["userPhone"];
          String healthStatus =
              (snapData.snapshot.value! as Map)["HealthStatus"] ?? "N/A";

          // Create a RideRequestInformation object to store the details
          RideRequestInformation rideRequestInformation =
              RideRequestInformation(
            rideRequestId: rideRequestID,
            userName: userName,
            userPhone: userPhone,
            sourceLatLng: LatLng(sourceLat, sourceLng),
            destinationLatLng: LatLng(destinationLat, destinationLng),
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            healthStatus: healthStatus,
          );

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => NotificationDialogBox(
              rideRequestInformation: rideRequestInformation,
              onDialogDismissed: () {
                _isDialogShown = false;
              },
            ),
          );
        }
      } else {
        Fluttertoast.showToast(msg: "This ride request no longer exists.");
      }
    });
  }
}
