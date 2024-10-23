import 'package:drivers_app/assistants/geofire.dart';
import 'package:drivers_app/global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FareAmountDialog extends StatefulWidget {
  final String? fareAmount;
  final String? userName;

  FareAmountDialog({this.fareAmount, this.userName});

  @override
  State<FareAmountDialog> createState() => _FareAmountDialogState();
}

class _FareAmountDialogState extends State<FareAmountDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10), // Slightly increased border radius
      ),
      backgroundColor: Colors.black, // Black background color
      child: Container(
        margin: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildFareAmount(),
              const SizedBox(height: 40),
              const Divider(
                color: Colors.white, // White divider line
                thickness: 1,
              ),
              const SizedBox(height: 20),
              _buildPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.monetization_on,
          color: Colors.yellow,
          size: 28,
        ),
        const SizedBox(width: 10),
        const Text(
          "Tarif En TND",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.yellow,
          ),
        ),
      ],
    );
  }

  Widget _buildFareAmount() {
    return Text(
      widget.fareAmount?.toString() ?? "N/A", // Safeguard for null fareAmount
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: _handlePayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        "Montant Payé",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  void _handlePayment() {
    _setDriverOnline();
  }

  Future<void> _setDriverOnline() async {
    driverCurrentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _updateDriverLocation();
    _updateDriverStatus();
    _navigateToMainScreen();
  }

  void _updateDriverLocation() {
    Geofire.initialize("ActiveDrivers");
    Geofire.setLocation(
      currentFirebaseUser!.uid,
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude,
    );
  }

  void _updateDriverStatus() {
    final driverRef = FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentFirebaseUser!.uid);

    driverRef.child("Status").set("Free");
    driverRef.child("newRideStatus").set("Idle");
  }

  void _navigateToMainScreen() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/main_screen",
      (route) => false,
    );
  }
}
