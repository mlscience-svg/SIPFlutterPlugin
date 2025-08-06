import 'package:flutter/material.dart';
import 'main_page.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(
        body: MainPage(),
      ),
    );
  }
}
