import 'dart:async';
import 'dart:ui';

// import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/models/driver_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentFirebaseUser;
UserModel? currentUserInfo;
StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverPosition;
// AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
Position? driverCurrentPosition;
DriverData driverData = DriverData();
String statusText = "Offline";
Color buttonColor = Colors.black;
bool isDriverActive = false;
//double montant=0.0;
DateTime now = DateTime.now();
double sourceLatitude = 0.0;
double destinationLongitude = 0.0;
double sourceLongitude = 0.0;
double destinationLatitude = 0.0;
