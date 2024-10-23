import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:dart_geohash/dart_geohash.dart';

class Geofire {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static late DatabaseReference _reference;
  static GeoHasher geoHasher = GeoHasher();

  // Initialize the node in the Firebase Realtime Database
  static void initialize(String node) {
    _reference = _database.ref().child(node);
    log("Geofire initialized at node: $node");
  }

  // Set location using latitude, longitude and save the geohash
  static Future<void> setLocation(
      String id, double latitude, double longitude) async {
    String geohash = geoHasher.encode(longitude, latitude, precision: 10);
    await _reference.child(id).set({
      'g': geohash, // Store geohash with key "g"
      'l': [
        latitude,
        longitude
      ], // Store latitude and longitude as a list under key "l"
    });
    log("Location set for ID: $id with geohash: $geohash");
  }

  // Remove location from the Firebase Realtime Database
  static Future<void> removeLocation(String id) async {
    await _reference.child(id).remove();
    log("Location removed for ID: $id");
  }

  // Get a location by ID
  static Future<Map<String, dynamic>?> getLocation(String id) async {
    DataSnapshot snapshot = (await _reference.child(id).once()).snapshot;
    if (snapshot.exists) {
      Map<String, dynamic> locationData =
          snapshot.value as Map<String, dynamic>;
      log("Location retrieved for ID: $id: $locationData");
      return locationData;
    } else {
      log("No location found for ID: $id");
      return null;
    }
  }

  // Query for nearby locations by geohash within a certain radius
  static Future<List<Map<String, dynamic>>> queryNearbyLocations(
      double latitude, double longitude, int precision) async {
    String geohash =
        geoHasher.encode(latitude, longitude, precision: precision);
    Map<String, String> neighbors = geoHasher.neighbors(geohash);

    List<Map<String, dynamic>> nearbyLocations = [];

    // Fetch locations within the current geohash and its 8 neighbors
    await Future.forEach(neighbors.values, (String neighborGeohash) async {
      DatabaseEvent snapshot = await _reference
          .orderByChild("g")
          .startAt(neighborGeohash)
          .endAt(neighborGeohash + "\uf8ff") // Searching within geohash range
          .once();

      if (snapshot.snapshot.exists) {
        Map<dynamic, dynamic> values =
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          nearbyLocations.add(value);
        });
      }
    });

    log("Nearby locations found: ${nearbyLocations.length}");
    return nearbyLocations;
  }
}
