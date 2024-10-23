import 'dart:async';
import 'package:drivers_app/push_notifications/push_notifications_system.dart';
import 'package:flutter/material.dart';
import '../assistants/assistant_methods.dart';
import '../global/global.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  startTimer() {
    //Fetching the User Data
    firebaseAuth.currentUser != null
        ? AssistantMethods.readOnlineUserCurrentInfo()
        : null;

    Timer(const Duration(seconds: 5), () async {
      if (await firebaseAuth.currentUser != null) {
        // send User to main screen
        currentFirebaseUser = firebaseAuth.currentUser;
        Navigator.pushNamed(context, '/main_screen');
      } else {
        // send User to login screen
        Navigator.pushNamed(context, '/login_screen');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    PushNotificationSystem pushNotificationSystem = PushNotificationSystem();
    pushNotificationSystem.initializeCloudMessaging(context).then((value) {
      // snackbar

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification initialized'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("images/logoCh.png"),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
