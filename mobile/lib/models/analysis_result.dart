/// Résultat d'une analyse renvoyé par POST /analyze.
///
/// Miroir exact du modèle Pydantic `AnalyzeResponse` (app/schemas.py) :
/// mêmes 5 champs, tous obligatoires.
class AnalysisResult {
  const AnalysisResult({
    required this.score,
    required this.matchedSkills,
    required this.missingSkills,
    required this.summary,
    required this.advice,
  });

  final int score;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String summary;
  final List<String> advice;

  /// Construit un résultat à partir du JSON de l'API.
  ///
  /// Lève une [FormatException] si un champ manque ou n'a pas le bon type :
  /// on ne fait pas confiance aux données reçues, comme Pydantic côté serveur.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    if (score is! int || score < 0 || score > 100) {
      throw const FormatException('"score" doit être un entier entre 0 et 100');
    }

    return AnalysisResult(
      score: score,
      matchedSkills: _readStringList(json, 'matched_skills'),
      missingSkills: _readStringList(json, 'missing_skills'),
      summary: _readString(json, 'summary'),
      advice: _readStringList(json, 'advice'),
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('"$key" doit être une chaîne de caractères');
    }
    return value;
  }

  static List<String> _readStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('"$key" doit être une liste de chaînes');
    }
    return List<String>.from(value);
  }
}
