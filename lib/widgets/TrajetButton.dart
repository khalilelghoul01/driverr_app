import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrajetButton extends StatefulWidget {
  final String statut;
  final double driverLat;
  final double driverLng;
  final double sourceLat;
  final double sourceLng;
  final double destinationLat;
  final double destinationLng;

  TrajetButton({
    required this.statut,
    required this.driverLat,
    required this.driverLng,
    required this.sourceLat,
    required this.sourceLng,
    required this.destinationLat,
    required this.destinationLng,
  });

  @override
  _TrajetButtonState createState() => _TrajetButtonState();
}

class _TrajetButtonState extends State<TrajetButton> {
  late IconData buttonIcon;

  @override
  void initState() {
    super.initState();
    _updateButtonIcon(widget.statut); // Initialiser l'icône du bouton
  }

  void _updateButtonIcon(String statut) {
    setState(() {
      if (statut == 'Accepted') {
        buttonIcon = Icons.directions_car; // Icône pour "Lancer GPS vers Client"
      } else {
        buttonIcon = Icons.navigation; // Icône pour "Lancer GPS vers la Destination"
      }
    });
  }

  @override
  void didUpdateWidget(TrajetButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Met à jour l'icône si le statut change
    if (oldWidget.statut != widget.statut) {
      _updateButtonIcon(widget.statut);
    }
  }

  void _launchMaps() async {
    Uri googleMapsUrl;
    if (widget.statut == 'Accepted') {
      googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${widget.driverLat},${widget.driverLng}&destination=${widget.sourceLat},${widget.sourceLng}&travelmode=driving');
    } else {
      googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${widget.sourceLat},${widget.sourceLng}&destination=${widget.destinationLat},${widget.destinationLng}&travelmode=driving');
    }

    print('URL Google Maps: $googleMapsUrl');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Impossible d\'ouvrir Google Maps.';
    }
  }

@override
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: _launchMaps,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min, // S'assure que le bouton n'est pas trop large
      children: [
        Icon(
          buttonIcon, // Affiche l'icône
          size: 24.0, // Taille de l'icône
        ),
        const SizedBox(width: 8), // Espacement entre l'icône et le texte
        const Text("GPS"), // Le texte à afficher
      ],
    ),
  );
}

}
