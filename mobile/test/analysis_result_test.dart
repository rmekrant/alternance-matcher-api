import 'dart:convert';

import 'package:alternance_matcher/models/analysis_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une réponse valide, au format exact renvoyé par l'API FastAPI.
Map<String, dynamic> validJson() => {
      'score': 65,
      'matched_skills': ['Python', 'SQL', 'Git'],
      'missing_skills': ['FastAPI', 'Docker'],
      'summary': 'Bon socle Python et SQL.',
      'advice': ['Ajouter un projet FastAPI.'],
    };

void main() {
  group('AnalysisResult.fromJson', () {
    test('lit une réponse valide de l API', () {
      // On passe par jsonEncode/jsonDecode pour reproduire exactement
      // ce que le client HTTP recevra : du texte JSON décodé en Map.
      final decoded = jsonDecode(jsonEncode(validJson())) as Map<String, dynamic>;

      final result = AnalysisResult.fromJson(decoded);

      expect(result.score, 65);
      expect(result.matchedSkills, ['Python', 'SQL', 'Git']);
      expect(result.missingSkills, ['FastAPI', 'Docker']);
      expect(result.summary, 'Bon socle Python et SQL.');
      expect(result.advice, ['Ajouter un projet FastAPI.']);
    });

    test('accepte des listes vides', () {
      final json = validJson()
        ..['matched_skills'] = <String>[]
        ..['advice'] = <String>[];

      final result = AnalysisResult.fromJson(json);

      expect(result.matchedSkills, isEmpty);
      expect(result.advice, isEmpty);
    });

    test('refuse une réponse où il manque un champ', () {
      final json = validJson()..remove('summary');

      expect(() => AnalysisResult.fromJson(json), throwsFormatException);
    });

    test('refuse un score hors de 0 à 100', () {
      final json = validJson()..['score'] = 150;

      expect(() => AnalysisResult.fromJson(json), throwsFormatException);
    });

    test('refuse un score qui n est pas un entier', () {
      final json = validJson()..['score'] = '65';

      expect(() => AnalysisResult.fromJson(json), throwsFormatException);
    });

    test('refuse une liste qui contient autre chose que du texte', () {
      final json = validJson()..['advice'] = ['Conseil', 42];

      expect(() => AnalysisResult.fromJson(json), throwsFormatException);
    });

    test('refuse une liste remplacée par une chaîne', () {
      final json = validJson()..['matched_skills'] = 'Python, SQL';

      expect(() => AnalysisResult.fromJson(json), throwsFormatException);
    });
  });
}
