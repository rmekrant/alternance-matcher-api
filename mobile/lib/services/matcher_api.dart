import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analysis_result.dart';

/// Erreur prête à être affichée à l'utilisateur.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client de l'API Alternance Matcher.
///
/// Le [http.Client] est injecté : l'app passe un vrai client, les tests un
/// MockClient. C'est le même principe que Depends côté FastAPI.
class MatcherApi {
  MatcherApi({
    required this.client,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 60),
  });

  /// Longueur minimale d'un texte, identique à min_length dans app/schemas.py.
  static const int minTextLength = 50;

  final http.Client client;
  final String baseUrl;
  final Duration timeout;

  /// Envoie l'offre et le CV à POST /analyze et renvoie le résultat.
  ///
  /// Lève une [ApiException] avec un message clair dans tous les cas d'erreur.
  Future<AnalysisResult> analyze({
    required String jobOffer,
    required String cv,
  }) async {
    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$baseUrl/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'job_offer': jobOffer, 'cv': cv}),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        "L'analyse prend trop de temps. Réessayez dans quelques instants.",
      );
    } on http.ClientException {
      throw const ApiException(
        "Impossible de joindre l'API. Vérifiez qu'elle est lancée.",
      );
    }

    if (response.statusCode == 200) {
      return _parseResult(response);
    }
    throw ApiException(_errorMessage(response));
  }

  AnalysisResult _parseResult(http.Response response) {
    try {
      // bodyBytes + utf8 : FastAPI n'indique pas de charset, et response.body
      // décoderait alors en latin1, ce qui casserait les accents.
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Un objet JSON était attendu');
      }
      return AnalysisResult.fromJson(json);
    } on FormatException {
      // JSON illisible, ou champ manquant / mal typé (levé par fromJson)
      throw const ApiException("L'API a renvoyé une réponse invalide.");
    }
  }

  String _errorMessage(http.Response response) {
    if (response.statusCode == 422) {
      return "Le CV et l'offre doivent faire chacun entre 50 et 20 000 caractères.";
    }

    // 502, 503, 504 : le backend renvoie {"detail": "message en français"}
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map && json['detail'] is String) {
        return json['detail'] as String;
      }
    } on FormatException {
      // Corps illisible : on utilise le message générique ci-dessous.
    }
    return 'Erreur du serveur (code ${response.statusCode}).';
  }
}
