import 'package:drivers_app/assistants/geofire.dart';
import 'package:drivers_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_geofire/flutter_geofire.dart';

class AccountDeletionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Désactivation du compte'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Supprimer les informations dans Firebase Realtime Database
              await driverIsOfflineNow();
              firebaseAuth.signOut();

              // Supprimer le compte Firebase Authentication
              await FirebaseAuth.instance.currentUser!.delete();

              // Déconnexion après la suppression

              // Redirection vers l'écran principal
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            } catch (e) {
              // Gestion des erreurs (ex: si l'utilisateur doit se reconnecter avant de supprimer)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erreur : ${e.toString()}")),
              );
            }
          },
          child: Text('Confirmer la désactivation'),
        ),
      ),
    );
  }

  Future<void> driverIsOfflineNow() async {
    // Suppression des informations de l'utilisateur dans Realtime Firebase
    Geofire.removeLocation(currentFirebaseUser!.uid);
    DatabaseReference? reference = FirebaseDatabase.instance
        .ref()
        .child("Drivers")
        .child(currentFirebaseUser!.uid);

    await reference.remove();
    currentFirebaseUser = null;
  }
}
