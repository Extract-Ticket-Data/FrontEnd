import 'package:bottomnav/pages/home_screen.dart';
import 'package:bottomnav/pages/splash_screen.dart';
import 'package:flutter/material.dart';

var routes = <String, WidgetBuilder>{
  "/home": (BuildContext context) => ImageInput(),
  //"/intro": (BuildContext context) => IntroScreen(),
};

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ticket Data Extractor',
        theme: ThemeData(primarySwatch: Colors.pink),
        debugShowCheckedModeBanner: false,
        home: SplashScreen());
        //routes: routes);
        //ImageInput());
  }
}


