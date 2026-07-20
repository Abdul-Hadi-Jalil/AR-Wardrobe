import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for the "Nano Banana" image model used by AI virtual try-on.
///
/// SECURITY NOTE: For a production app, do NOT hardcode API keys in source.
/// Move this to an environment variable / secure store (e.g. --dart-define) and
/// keep it out of version control. The key below is for local testing only.
class ApiConfig {
  ApiConfig._();

  /// API key for the image model.
  ///
  /// For the official Google Gemini ("Nano Banana") API, this must be a Google
  /// AI Studio key that begins with `AIza...`. Get one at
  /// https://aistudio.google.com/app/apikey
  static final String geminiApiKey = dotenv.env['GCP_API_KEY'] ?? '';

  /// Model id for Nano Banana (Gemini 2.5 Flash Image).
  static const String imageModel = 'gemini-2.5-flash-image';

  /// Base endpoint for the Generative Language API.
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static bool get hasKey =>
      geminiApiKey.isNotEmpty && geminiApiKey != dotenv.env['GCP_API_KEY'];

  // --- FASHN.ai (dedicated virtual try-on, used as a fallback) ---

  /// FASHN API key (Bearer token, begins with `fa-`).
  /// Get one at https://app.fashn.ai/ -> API.
  static final String fashnApiKey = dotenv.env['FASHN_API_KEY'] ?? '';

  /// FASHN try-on model id.
  static const String fashnModel = 'tryon-v1.6';

  /// FASHN API base URL.
  static const String fashnBaseUrl = 'https://api.fashn.ai/v1';

  static bool get hasFashnKey => fashnApiKey.isNotEmpty;
}
