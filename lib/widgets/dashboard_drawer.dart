import 'dart:convert';
import 'dart:typed_data';

import 'package:drivers_app/assistants/geofire.dart';
import 'package:drivers_app/authentication/delete_account.dart';
import 'package:drivers_app/mainScreens/edit_profile_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/mainScreens/profile_screen.dart';
import 'package:drivers_app/mainScreens/trip_history_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_geofire/flutter_geofire.dart';
class DashboardDrawer extends StatefulWidget {
  final String? name;
  String? photoUrl;
  DashboardDrawer({this.name, this.photoUrl});

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
  driverIsOfflineNow() async {
    Geofire.removeLocation(currentFirebaseUser!.uid);
    DatabaseReference? reference = FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    reference.onDisconnect();
    reference.remove();
    reference = null;

    DatabaseReference activeDriverRef = FirebaseDatabase.instance
        .ref()
        .child("ActiveDrivers")
        .child(currentFirebaseUser!.uid);
    activeDriverRef.remove();
    currentFirebaseUser = null;
  }

  void _callSupport() async {
    const phoneNumber = 'tel:+21695125458';
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            height: 165,
            color: Colors.black,
            child: DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: driverData.photoUrl != null
                        ? NetworkImage(driverData.photoUrl!)
                        : null,
                    child: driverData.photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        driverData.name!,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              driverIsOfflineNow().then((_) {
                firebaseAuth.signOut();
                Navigator.pushNamed(context, '/');
              });
            },
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.black),
              title: Text(
                AppLocalizations.of(context)!.signout,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AccountDeletionScreen()));
            },
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.black),
              title: Text(
                "Désactiver mon Compte",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          GestureDetector(
            onTap: _callSupport,
            child: ListTile(
              leading: Icon(Icons.support_agent, color: Colors.black),
              title: Text(
                "Appeler le Support",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List ImageMemoryWidget() {
    String imageData = driverData.photoUrl!.split(',')[1];
    Uint8List bytes = base64.decode(imageData);
    return bytes;
  }
}
