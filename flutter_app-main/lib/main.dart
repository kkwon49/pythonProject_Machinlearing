import 'package:fl_new/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'package:fl_new/scan_screen.dart';
import 'dart:io' show Platform;

Future<void> _requestPermissions() async {
  await Permission.bluetooth.request();
  await Permission.location.request();
  await Permission.bluetoothScan.request();
  await Permission.bluetoothAdvertise.request();
  await Permission.bluetoothConnect.request();
  await Permission.storage.request();
}

Future<void> main() async {
  // firebase initialization
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
  ]);

  bool supportedPlatform = Platform.isAndroid || Platform.isIOS;
  if (supportedPlatform) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await _requestPermissions();
  runApp(Biomonitor(supportedPlatform: supportedPlatform));
}

class Biomonitor extends StatelessWidget {
  final bool supportedPlatform;
  const Biomonitor({required this.supportedPlatform, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Yeo Lab Tablet App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: AppTheme.textTheme,
        platform: TargetPlatform.android,
        primaryColorLight: const Color(0xCCCCCCCC),
        primaryTextTheme: const TextTheme(
          labelMedium: TextStyle(
            fontSize: 20,
            color: Colors.black,
          ),
          labelSmall: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textTheme: AppTheme.textTheme,
        platform: TargetPlatform.android,
        primaryColorLight: const Color(0xCCCCCCCC),
        primaryTextTheme: const TextTheme(
          labelMedium: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
          labelSmall: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: ScanScreen()),
    );
  }
}
