import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'try_on_result.dart';

/// Thin client for Google's "Nano Banana" (Gemini 2.5 Flash Image) model.
///
/// Sends a person photo + a garment photo and asks the model to render the
/// same person wearing the garment.
class NanoBananaService {
  NanoBananaService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _defaultPrompt =
      'You are a virtual try-on assistant. The FIRST image is a photo of a '
      'person. The SECOND image is a clothing item. Generate a single new '
      'photorealistic image of the SAME person now wearing the clothing item '
      'from the second image. Preserve the person\'s face, hair, body shape, '
      'pose, skin tone, lighting and background exactly. Fit the garment '
      'naturally onto their body with realistic folds, shadows and proportions. '
      'Output only the final image.';

  Uri get _endpoint => Uri.parse(
        '${ApiConfig.geminiBaseUrl}/models/${ApiConfig.imageModel}:generateContent',
      );

  /// Generates a try-on image from raw bytes of the person and garment images.
  Future<TryOnResult> generateTryOn({
    required Uint8List personImage,
    required String personMimeType,
    required Uint8List clothImage,
    required String clothMimeType,
    String? prompt,
  }) async {
    if (!ApiConfig.hasKey) {
      return const TryOnResult(
        engine: 'Gemini',
        error: 'No Gemini API key configured.',
      );
    }

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt ?? _defaultPrompt},
            {
              'inline_data': {
                'mime_type': personMimeType,
                'data': base64Encode(personImage),
              }
            },
            {
              'inline_data': {
                'mime_type': clothMimeType,
                'data': base64Encode(clothImage),
              }
            },
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': ['IMAGE'],
      },
    });

    try {
      final response = await _client
          .post(
            _endpoint,
            headers: {
              'x-goog-api-key': ApiConfig.geminiApiKey,
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 90));

      return _parseResponse(response.statusCode, response.body)
          .copyWith(engine: 'Gemini');
    } catch (e) {
      return TryOnResult(engine: 'Gemini', error: 'Request failed: $e');
    }
  }

  TryOnResult _parseResponse(int statusCode, String responseBody) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      return TryOnResult(error: 'Unexpected response (HTTP $statusCode).');
    }

    if (json['error'] != null) {
      final message = json['error']['message'] ?? 'Unknown API error';
      return TryOnResult(error: '$message (HTTP $statusCode)');
    }

    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      return const TryOnResult(error: 'The model returned no result.');
    }

    final parts =
        (candidates.first['content']?['parts'] as List?) ?? const [];

    String? text;
    for (final part in parts) {
      final map = part as Map<String, dynamic>;
      final inline = map['inline_data'] ?? map['inlineData'];
      if (inline != null && inline['data'] != null) {
        try {
          final bytes = base64Decode(inline['data'] as String);
          return TryOnResult(image: bytes, text: text);
        } catch (_) {
          return const TryOnResult(error: 'Could not decode the result image.');
        }
      }
      if (map['text'] != null) {
        text = (text == null) ? map['text'] as String : '$text${map['text']}';
      }
    }

    return TryOnResult(
      text: text,
      error: text == null
          ? 'The model did not return an image.'
          : 'The model responded with text instead of an image.',
    );
  }

  void dispose() => _client.close();
}
