import 'dart:typed_data';

/// Result of a virtual try-on generation request, shared across providers.
class TryOnResult {
  const TryOnResult({this.image, this.text, this.error, this.engine});

  /// Generated image bytes (PNG/JPEG) when successful.
  final Uint8List? image;

  /// Any text the model returned alongside (or instead of) an image.
  final String? text;

  /// Human-readable error message when the request failed.
  final String? error;

  /// Which engine produced this result (e.g. 'Gemini', 'FASHN').
  final String? engine;

  bool get isSuccess => image != null;

  TryOnResult copyWith({String? engine}) => TryOnResult(
        image: image,
        text: text,
        error: error,
        engine: engine ?? this.engine,
      );
}
