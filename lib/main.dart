import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:social_network/screens/activity_feed.dart';
import 'package:social_network/screens/home.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages('id', timeago.IdMessages());

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey =
      new GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    initPlatformState();
  }

  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print(e);
    }
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;

    OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    OneSignal.shared
        .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
      print('NOTIFICATION OPENED HANDLER CALLED WITH: $result');

      _handleNavigate();
    });

    OneSignal.shared.setNotificationWillShowInForegroundHandler(
        (OSNotificationReceivedEvent event) {
      print('FOREGROUND HANDLER CALLED WITH: ${event}');
    });

    await OneSignal.shared.setAppId("145696f0-1996-41ba-8589-2a3616d10d54");

    OneSignal.shared.disablePush(false);
  }

  _handleNavigate() {
    Navigator.of(_navigatorKey.currentContext!)
        .push(MaterialPageRoute(builder: (context) => ActivityFeed()));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Social Network',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // accentColor: Colors.indigo[400],
      ),
      home: Home(),
    );
  }
}
