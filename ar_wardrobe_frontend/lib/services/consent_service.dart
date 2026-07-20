import 'package:shared_preferences/shared_preferences.dart';

/// Persists user consent for photo capture, storage, and AI processing.
class ConsentService {
  ConsentService._();

  static const _key = 'photo_terms_consent_v1';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> revoke() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
