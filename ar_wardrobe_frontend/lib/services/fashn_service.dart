import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'try_on_result.dart';

/// Client for the FASHN.ai virtual try-on API.
///
/// FASHN is asynchronous: submit a job to `/v1/run`, then poll `/v1/status/{id}`
/// until it completes and exposes the output image(s).
class FashnService {
  FashnService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _pollInterval = Duration(seconds: 3);
  static const int _maxPolls = 40; // ~2 minutes

  Uri get _runUrl => Uri.parse('${ApiConfig.fashnBaseUrl}/run');
  Uri _statusUrl(String id) =>
      Uri.parse('${ApiConfig.fashnBaseUrl}/status/$id');

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${ApiConfig.fashnApiKey}',
        'Content-Type': 'application/json',
      };

  Future<TryOnResult> generateTryOn({
    required Uint8List personImage,
    required String personMimeType,
    required Uint8List clothImage,
    required String clothMimeType,
  }) async {
    if (!ApiConfig.hasFashnKey) {
      return const TryOnResult(
        engine: 'FASHN',
        error: 'No FASHN API key configured.',
      );
    }

    final personUri =
        'data:$personMimeType;base64,${base64Encode(personImage)}';
    final clothUri = 'data:$clothMimeType;base64,${base64Encode(clothImage)}';

    final body = jsonEncode({
      'model_name': ApiConfig.fashnModel,
      'inputs': {
        'model_image': personUri,
        'garment_image': clothUri,
        'return_base64': true,
      },
    });

    try {
      final runResponse = await _client
          .post(_runUrl, headers: _headers, body: body)
          .timeout(const Duration(seconds: 60));

      Map<String, dynamic> runJson;
      try {
        runJson = jsonDecode(runResponse.body) as Map<String, dynamic>;
      } catch (_) {
        return TryOnResult(
          engine: 'FASHN',
          error: 'Unexpected response (HTTP ${runResponse.statusCode}).',
        );
      }

      if (runResponse.statusCode == 401 || runResponse.statusCode == 403) {
        return const TryOnResult(
          engine: 'FASHN',
          error: 'FASHN authentication failed. Check the API key.',
        );
      }

      if (runJson['error'] != null) {
        return TryOnResult(
          engine: 'FASHN',
          error: _stringifyError(runJson['error']),
        );
      }

      final id = runJson['id'] as String?;
      if (id == null) {
        return const TryOnResult(
          engine: 'FASHN',
          error: 'FASHN did not return a prediction id.',
        );
      }

      return await _pollForResult(id);
    } catch (e) {
      return TryOnResult(engine: 'FASHN', error: 'Request failed: $e');
    }
  }

  Future<TryOnResult> _pollForResult(String id) async {
    for (var attempt = 0; attempt < _maxPolls; attempt++) {
      await Future.delayed(_pollInterval);

      final statusResponse =
          await _client.get(_statusUrl(id), headers: _headers);
      Map<String, dynamic> json;
      try {
        json = jsonDecode(statusResponse.body) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }

      final status = json['status'] as String?;
      switch (status) {
        case 'completed':
          return await _imageFromOutput(json['output']);
        case 'failed':
          return TryOnResult(
            engine: 'FASHN',
            error: _stringifyError(json['error']) ?? 'Generation failed.',
          );
        default:
          // starting / in_queue / processing -> keep polling
          break;
      }
    }
    return const TryOnResult(
      engine: 'FASHN',
      error: 'Timed out waiting for FASHN result.',
    );
  }

  Future<TryOnResult> _imageFromOutput(dynamic output) async {
    if (output is! List || output.isEmpty) {
      return const TryOnResult(
        engine: 'FASHN',
        error: 'FASHN returned no output image.',
      );
    }

    final first = output.first as String;

    // Base64 data URI.
    if (first.startsWith('data:')) {
      final comma = first.indexOf(',');
      final b64 = comma >= 0 ? first.substring(comma + 1) : first;
      try {
        return TryOnResult(engine: 'FASHN', image: base64Decode(b64));
      } catch (_) {
        return const TryOnResult(
          engine: 'FASHN',
          error: 'Could not decode the result image.',
        );
      }
    }

    // CDN URL -> download the bytes.
    try {
      final imgResponse = await _client.get(Uri.parse(first));
      if (imgResponse.statusCode == 200) {
        return TryOnResult(engine: 'FASHN', image: imgResponse.bodyBytes);
      }
      return TryOnResult(
        engine: 'FASHN',
        error: 'Could not download result (HTTP ${imgResponse.statusCode}).',
      );
    } catch (e) {
      return TryOnResult(engine: 'FASHN', error: 'Download failed: $e');
    }
  }

  String? _stringifyError(dynamic error) {
    if (error == null) return null;
    if (error is String) return error;
    if (error is Map) {
      return error['message']?.toString() ?? error.toString();
    }
    return error.toString();
  }

  void dispose() => _client.close();
}
