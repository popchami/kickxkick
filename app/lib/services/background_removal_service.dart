import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackgroundRemovalService {
  Future<String> removeEdgeBackground(String sourcePath, int shoeId) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('画像を読み込めませんでした');
    final image = decoded.width > 1400 ? img.copyResize(decoded, width: 1400) : decoded;
    final corners = [
      image.getPixel(0, 0),
      image.getPixel(image.width - 1, 0),
      image.getPixel(0, image.height - 1),
      image.getPixel(image.width - 1, image.height - 1),
    ];
    final r = corners.map((e) => e.r.toDouble()).reduce((a, b) => a + b) / 4;
    final g = corners.map((e) => e.g.toDouble()).reduce((a, b) => a + b) / 4;
    final b = corners.map((e) => e.b.toDouble()).reduce((a, b) => a + b) / 4;
    const threshold = 58.0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final edgeDistance = min(min(x, image.width - 1 - x), min(y, image.height - 1 - y));
        if (edgeDistance > min(image.width, image.height) * 0.28) continue;
        final pixel = image.getPixel(x, y);
        final distance = sqrt(pow(pixel.r - r, 2) + pow(pixel.g - g, 2) + pow(pixel.b - b, 2));
        if (distance < threshold) {
          final alpha = ((distance / threshold) * 255).round().clamp(0, 255);
          image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
        }
      }
    }
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'kickxkick', 'stickers'));
    await directory.create(recursive: true);
    final output = p.join(directory.path, 'shoe_${shoeId}_${DateTime.now().millisecondsSinceEpoch}.png');
    await File(output).writeAsBytes(Uint8List.fromList(img.encodePng(image)));
    return output;
  }
}
