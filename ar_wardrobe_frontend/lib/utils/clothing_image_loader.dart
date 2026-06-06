import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/clothing_item.dart';

class ClothingImageLoader {
  static Future<ui.Image> load(String assetPath, ClothingCategory category) async {
    final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
    final removeWhite = category != ClothingCategory.glasses;

    if (!removeWhite) {
      return _decodeToUiImage(bytes);
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return _decodeToUiImage(bytes);
    }

    _stripWhiteBackground(decoded);
    return _decodeToUiImage(Uint8List.fromList(img.encodePng(decoded)));
  }

  static void _stripWhiteBackground(img.Image image) {
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final a = pixel.a.toInt();

        if (a < 16 || _isWhiteBackground(r, g, b)) {
          image.setPixelRgba(x, y, r, g, b, 0);
        }
      }
    }
  }

  static bool _isWhiteBackground(int r, int g, int b) {
    if (r > 245 && g > 245 && b > 245) return true;

    final brightness = (r + g + b) / 3;
    final maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final saturation = maxChannel - minChannel;

    return brightness > 210 && saturation < 35;
  }

  static Future<ui.Image> _decodeToUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
