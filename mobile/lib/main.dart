import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'screens/analyze_screen.dart';
import 'services/matcher_api.dart';

void main() {
  // Le vrai client HTTP est créé ici, une seule fois, puis transmis à l'écran.
  final api = MatcherApi(client: http.Client(), baseUrl: apiBaseUrl);
  runApp(MatcherApp(api: api));
}

class MatcherApp extends StatelessWidget {
  const MatcherApp({super.key, required this.api});

  final MatcherApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alternance Matcher',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: AnalyzeScreen(api: api),
    );
  }
}
