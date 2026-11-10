import 'dart:async';
import 'dart:convert';

import 'package:alternance_matcher/screens/analyze_screen.dart';
import 'package:alternance_matcher/services/matcher_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const cv = "Étudiant ingénieur à l'EFREI : projets en Python et SQL, Git au quotidien.";
const offer = 'Alternance développeur backend : Python, FastAPI, SQL, Docker et Git.';

const validResult = {
  'score': 65,
  'matched_skills': ['Python', 'SQL'],
  'missing_skills': ['Docker'],
  'summary': 'Bon socle Python et SQL.',
  'advice': ['Ajouter un projet Docker.'],
};

http.Response jsonResponse(Object body, int statusCode) {
  return http.Response.bytes(utf8.encode(jsonEncode(body)), statusCode);
}

/// Affiche l'écran avec un faux client HTTP : aucun appel à la vraie API.
Future<void> pumpScreen(WidgetTester tester, MockClient client) async {
  // Écran haut : le résultat entier tient à l'écran, donc la ListView le construit.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final api = MatcherApi(client: client, baseUrl: 'http://test');
  await tester.pumpWidget(MaterialApp(home: AnalyzeScreen(api: api)));
}

Future<void> fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('cvField')), cv);
  await tester.enterText(find.byKey(const Key('offerField')), offer);
  await tester.tap(find.byKey(const Key('analyzeButton')));
}

void main() {
  testWidgets('champs vides : message d erreur et aucun appel réseau', (tester) async {
    var calls = 0;
    await pumpScreen(
      tester,
      MockClient((_) async {
        calls++;
        return jsonResponse(validResult, 200);
      }),
    );

    await tester.tap(find.byKey(const Key('analyzeButton')));
    await tester.pump();

    expect(find.text("Remplissez le CV et l'offre."), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('succès : chargement puis affichage du résultat', (tester) async {
    // Le Completer permet de décider quand le faux serveur répond,
    // pour vérifier l'état de chargement entre les deux.
    final serverResponse = Completer<http.Response>();
    late http.Request sentRequest;
    await pumpScreen(
      tester,
      MockClient((request) {
        sentRequest = request;
        return serverResponse.future;
      }),
    );

    await fillAndSubmit(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    serverResponse.complete(jsonResponse(validResult, 200));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Score : 65/100'), findsOneWidget);
    expect(find.text('Bon socle Python et SQL.'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
    expect(find.text('Ajouter un projet Docker.'), findsOneWidget);
    expect(jsonDecode(sentRequest.body), {'job_offer': offer, 'cv': cv});
  });

  testWidgets('erreur du backend : affiche le message et réactive le bouton', (tester) async {
    await pumpScreen(
      tester,
      MockClient(
        (_) async => jsonResponse(
          {'detail': "Le service d'analyse a renvoyé une erreur."},
          502,
        ),
      ),
    );

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text("Le service d'analyse a renvoyé une erreur."), findsOneWidget);
    expect(find.text('Score : 65/100'), findsNothing);
    final button = tester.widget<FilledButton>(find.byKey(const Key('analyzeButton')));
    expect(button.onPressed, isNotNull);
  });
}
