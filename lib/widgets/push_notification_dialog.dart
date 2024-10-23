import 'dart:developer';
import 'package:drivers_app/assistants/assistant_methods.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/mainScreens/new_trip_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_request_information.dart';

class NotificationDialogBox extends StatelessWidget {
  final RideRequestInformation rideRequestInformation;
  final Function onDialogDismissed;

  const NotificationDialogBox({
    Key? key,
    required this.rideRequestInformation,
    required this.onDialogDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onDialogDismissed();
        return true;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.all(8),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo[900]!,
                Colors.indigo[700]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                _buildHeaderSection(context),
                const SizedBox(height: 24),
                _buildAddressSection(),
                const SizedBox(height: 24),
                _buildActionButtons(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
        ),
        Image.asset(
          "images/car_logo.png",
          width: 80,
          height: 80,
        ),
        Positioned(
          top: 90,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocalizations.of(context)!.newRideequest,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildAddressRow(
            icon: "images/source.png",
            address: rideRequestInformation.sourceAddress!,
            label: "From",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white30),
          ),
          _buildAddressRow(
            icon: "images/destination.png",
            address: rideRequestInformation.destinationAddress!,
            label: "To",
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(
      {required String icon, required String address, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            icon,
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context: context,
          label: AppLocalizations.of(context)!.cancel,
          color: Colors.red.shade400,
          onPressed: () {
            Navigator.pop(context);
            onDialogDismissed();
          },
        ),
        _buildActionButton(
          context: context,
          label: AppLocalizations.of(context)!.accept,
          color: Colors.green.shade400,
          onPressed: () => acceptRideRequest(context),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> acceptRideRequest(BuildContext context) async {
    // if the driver accept he change the status of the ride request to accepted
    log("Ride request accepted");
    if (rideRequestInformation.rideRequestId == null) {
      return;
    }
    final currentDriverId = FirebaseAuth.instance.currentUser!.uid;
    final position = await Geolocator.getCurrentPosition();
    FirebaseDatabase.instance
        .ref()
        .child("AllRideRequests")
        .child(rideRequestInformation.rideRequestId!)
        .child("driverId")
        .set(currentDriverId);

    final driver = await FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentDriverId)
        .once();
    final currentRequest = await FirebaseDatabase.instance
        .ref()
        .child("AllRideRequests")
        .child(rideRequestInformation.rideRequestId!)
        .once();
    if (driver.snapshot.value == null ||
        currentRequest.snapshot.value == null) {
      return;
    }

    await FirebaseDatabase.instance
        .ref()
        .child("AllRideRequests")
        .child(rideRequestInformation.rideRequestId!)
        .set({
      ...(currentRequest.snapshot.value as Map?)!,
      "driverId": currentDriverId,
      "driverName": (driver.snapshot.value as Map?)!["name"],
      "driverPhone": (driver.snapshot.value as Map?)!["phone"],
      "driverPhoto": (driver.snapshot.value as Map?)!["imageUrl"],
      "status": "accepted",
      "driverLocationData": {
        "latitude": position.latitude,
        "longitude": position.longitude,
      },
    });

    FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentDriverId)
        .child("newRideStatus")
        .set("Accepted");
    AssistantMethods.pauseLiveLocationUpdates();
    onDialogDismissed();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => NewTripScreen(
                  rideRequestInformation: rideRequestInformation,
                )));
  }
}
