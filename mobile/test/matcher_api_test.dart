import 'dart:async';
import 'dart:convert';

import 'package:alternance_matcher/services/matcher_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const validResult = {
  'score': 65,
  'matched_skills': ['Python'],
  'missing_skills': ['Docker'],
  'summary': 'Bonne expérience en Python.',
  'advice': ['Ajouter un projet Docker.'],
};

/// Réponse HTTP encodée en UTF-8, comme celle que renvoie FastAPI.
http.Response jsonResponse(Object body, int statusCode) {
  return http.Response.bytes(utf8.encode(jsonEncode(body)), statusCode);
}

/// Crée l'API avec un faux client : aucun appel réseau réel.
MatcherApi apiReturning(MockClientHandler handler, {Duration? timeout}) {
  return MatcherApi(
    client: MockClient(handler),
    baseUrl: 'http://test',
    timeout: timeout ?? const Duration(seconds: 60),
  );
}

/// Vérifie qu'un appel échoue avec une ApiException dont le message contient [text].
Matcher throwsApiException(String text) {
  return throwsA(
    isA<ApiException>().having((e) => e.message, 'message', contains(text)),
  );
}

void main() {
  test('envoie offre et CV en JSON sur POST /analyze et lit le résultat', () async {
    late http.Request sentRequest;
    final api = apiReturning((request) async {
      sentRequest = request;
      return jsonResponse(validResult, 200);
    });

    final result = await api.analyze(jobOffer: 'offre', cv: 'cv');

    expect(sentRequest.method, 'POST');
    expect(sentRequest.url.toString(), 'http://test/analyze');
    expect(sentRequest.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(sentRequest.body), {'job_offer': 'offre', 'cv': 'cv'});
    expect(result.score, 65);
    expect(result.summary, 'Bonne expérience en Python.'); // accents conservés
  });

  test('réponse 200 qui n est pas du JSON : réponse invalide', () async {
    final api = apiReturning((_) async => http.Response('pas du json', 200));

    await expectLater(
      api.analyze(jobOffer: 'offre', cv: 'cv'),
      throwsApiException('réponse invalide'),
    );
  });

  test('réponse 200 avec un champ manquant : réponse invalide', () async {
    final incomplete = Map.of(validResult)..remove('score');
    final api = apiReturning((_) async => jsonResponse(incomplete, 200));

    await expectLater(
      api.analyze(jobOffer: 'offre', cv: 'cv'),
      throwsApiException('réponse invalide'),
    );
  });

  test('erreur 503 : affiche le message detail du backend', () async {
    final api = apiReturning(
      (_) async => jsonResponse({'detail': 'Service indisponible.'}, 503),
    );

    await expectLater(
      api.analyze(jobOffer: 'offre', cv: 'cv'),
      throwsApiException('Service indisponible.'),
    );
  });

  test('erreur 422 : explique la contrainte de longueur', () async {
    final api = apiReturning(
      (_) async => jsonResponse({'detail': <Object>[]}, 422),
    );

    await expectLater(
      api.analyze(jobOffer: 'offre', cv: 'cv'),
      throwsApiException('50'),
    );
  });

  test('API injoignable : message de connexion', () async {
    final api = apiReturning(
      (_) async => throw http.ClientException('Connection refused'),
    );

    await expectLater(
      api.analyze(jobOffer: 'offre', cv: 'cv'),
      throwsApiException("Impossible de joindre l'API"),
    );
  });

  test('pas de réponse dans le délai : message de timeout', () async {
    // Le faux serveur ne répond jamais.
    final api = apiReturning(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      api.analyze(jobOffer: 'offre', cv: 'cv'),
      throwsApiException('trop de temps'),
    );
  });
}
