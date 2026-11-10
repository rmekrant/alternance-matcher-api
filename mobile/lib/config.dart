/// URL de base de l'API FastAPI.
///
/// Valeur par défaut : http://10.0.2.2:8000. Dans l'émulateur Android,
/// 10.0.2.2 désigne le PC qui fait tourner l'émulateur (localhost, lui,
/// désignerait l'émulateur lui-même).
///
/// Pour une autre adresse (vrai téléphone, serveur distant) :
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
