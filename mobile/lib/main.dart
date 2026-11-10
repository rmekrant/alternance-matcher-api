import 'package:flutter/material.dart';

void main() {
  runApp(const MatcherApp());
}

class MatcherApp extends StatelessWidget {
  const MatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alternance Matcher',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const Scaffold(
        body: Center(child: Text('Alternance Matcher')),
      ),
    );
  }
}