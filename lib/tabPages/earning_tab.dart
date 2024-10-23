import 'package:drivers_app/global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EarningsTabPage extends StatefulWidget {
  @override
  _EarningsTabPageState createState() => _EarningsTabPageState();
}

class _EarningsTabPageState extends State<EarningsTabPage> {
  String moisRevenus = "0.00";
  String aujourdHuiRevenus = "0.00";
  String nombreTrajets = '0';
  String dernierMontant = "0";

  @override
  void initState() {
    super.initState();
    fetchEarningsData();
  }

  void fetchEarningsData() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child('Drivers')
        .child(currentFirebaseUser!.uid);

    try {
      // Récupérer les données de Firebase
      DatabaseEvent event = await ref.once();

      // Extraire le snapshot de l'événement
      DataSnapshot snapshot = event.snapshot;

      // Vérifier si les données existent
      if (snapshot.value != null) {
        var data =
            Map<String, dynamic>.from(snapshot.value as Map<Object?, Object?>);

        // Log des données récupérées
        print("Données récupérées : $data");

        // Mettre à jour l'état avec les données récupérées
        double lastFare =
            double.tryParse(data['lastTripFare']?.toString() ?? '0.00') ?? 0.00;
        double monthEarnings =
            double.tryParse(data['monthEarnings']?.toString() ?? '0.00') ??
                0.00;
        double todayEarnings =
            double.tryParse(data['todayEarnings']?.toString() ?? '0.00') ??
                0.00;
        int tripCount = int.tryParse(data['tripCount']?.toString() ?? '0') ?? 0;

        setState(() {
          dernierMontant = lastFare.toStringAsFixed(1);
          moisRevenus = monthEarnings.toStringAsFixed(1);
          aujourdHuiRevenus = todayEarnings.toStringAsFixed(1);
          nombreTrajets = tripCount.toString();
        });
      } else {
        print('Aucune donnée trouvée pour l\'utilisateur');
      }
    } catch (e) {
      print('Erreur lors de la récupération des données : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Vos Revenus",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black,
          ),
        ),
        leading: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, "/main_screen");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
          ),
          child: Icon(
            Icons.arrow_back_outlined,
            color: Colors.redAccent,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  EarningsCard(
                    title: "Dernier Gain",
                    amount: "TD $dernierMontant", // Ajustez selon vos besoins
                    details: [
                      Detail(icon: Icons.car_rental, text: "Distance: 11KM"),
                      Detail(
                          icon: Icons.punch_clock_rounded,
                          text: "Temps: 11min"),
                    ],
                  ),
                  SizedBox(height: 30),
                  EarningsCard(
                    title: "Revenus Mensuelle",
                    amount: "TD $moisRevenus",
                    details: [
                      Detail(
                          icon: Icons.car_rental,
                          text: "$nombreTrajets trajets"),
                      Detail(icon: Icons.punch_clock_rounded, text: "N/A"),
                    ],
                  ),
                  SizedBox(height: 30),
                  EarningsCard(
                    title: "Revenus d'Aujourd'hui",
                    amount: "TD $aujourdHuiRevenus",
                    details: [],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      //Navigator.pop(context);
                      Navigator.pushNamed(context,
                          '/main_screen'); // Replace '/next_interface' with the route of your next interface.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.fromLTRB(50, 15, 50, 15),
                    ),
                    child: const Text(
                      "Retour à l'accueil",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EarningsCard extends StatelessWidget {
  final String title;
  final String amount;
  final List<Detail> details;

  EarningsCard(
      {required this.title, required this.amount, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              amount,
              style: TextStyle(
                fontSize: 25,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: details.map((detail) {
                return Row(
                  children: [
                    Icon(detail.icon, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(detail.text),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class Detail {
  final IconData icon;
  final String text;

  Detail({required this.icon, required this.text});
}
