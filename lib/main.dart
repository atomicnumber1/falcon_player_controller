import 'package:flutter/material.dart';

import 'package:falcon_player_controller/home.dart' show MyHomePage;

void main() {
  runApp(new MyApp());
}



class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'FPP Controller',
      theme: new ThemeData.light(),
      home: new MyHomePage(title: 'Falcon Player Controller'),
    );
  }
}