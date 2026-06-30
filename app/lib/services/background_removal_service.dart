import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackgroundRemovalService {
  static const _mlkitMarkerFile = '.mlkit_ready';

  /// Android + ML Kit の初回実行でモデルDLが必要かどうかを返す
  Future<bool> needsModelDownload() async {
    if (!Platform.isAndroid) return false;
    final root = await getApplicationDocumentsDirectory();
    final marker = File(p.join(root.path, 'kickxkick', _mlkitMarkerFile));
    return !await marker.exists();
  }

  /// 背景除去のエントリポイント
  /// Android: ML Kit Subject Segmentation → 失敗時はフラッドフィルにフォールバック
  /// iOS: フラッドフィルのみ
  Future<String> removeEdgeBackground(
    String sourcePath,
    int shoeId, {
    double threshold = 90,
  }) async {
    if (Platform.isAndroid) {
      try {
        return await _removeWithMlKit(sourcePath, shoeId, threshold: threshold);
      } catch (_) {
        return await _removeWithFloodFill(
          sourcePath,
          shoeId,
          threshold: threshold,
        );
      }
    }
    return _removeWithFloodFill(sourcePath, shoeId, threshold: threshold);
  }

  // ---------------------------------------------------------------------------
  // ML Kit Subject Segmentation (Android)
  // ---------------------------------------------------------------------------

  Future<String> _removeWithMlKit(
    String sourcePath,
    int shoeId, {
    required double threshold,
  }) async {
    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundConfidenceMask: true,
      ),
    );
    try {
      final result = await segmenter.processImage(
        InputImage.fromFilePath(sourcePath),
      );
      final mask = result.foregroundMask;
      if (mask == null) throw StateError('セグメンテーションマスクを取得できませんでした');

      // 出力画像を 1400px 以内にリサイズ
      final bytes = await File(sourcePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw StateError('画像を読み込めませんでした');
      final resized =
          decoded.width > 1400 ? img.copyResize(decoded, width: 1400) : decoded;
      final image = resized.convert(numChannels: 4);

      final maskW = mask.width;
      final maskH = mask.height;
      final outW = image.width;
      final outH = image.height;
      final confidences = mask.confidences;

      // 既存のスライダー値 (20-220) を確信度カットオフ (0.05-0.95) に変換
      // 低い値 → 前景を多く残す / 高い値 → より積極的に除去
      final cutoff = (threshold / 220.0).clamp(0.05, 0.95);
      final visited = Uint8List(outW * outH);

      for (var y = 0; y < outH; y++) {
        for (var x = 0; x < outW; x++) {
          // マスク座標を出力画像座標にスケール
          final maskX = (x * maskW / outW).round().clamp(0, maskW - 1);
          final maskY = (y * maskH / outH).round().clamp(0, maskH - 1);
          final c = confidences[maskY * maskW + maskX];
          if (c < cutoff) {
            final pixel = image.getPixel(x, y);
            image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
            visited[y * outW + x] = 1;
          }
        }
      }

      _smoothCutoutEdge(image, visited);
      final output = await _savePng(image, shoeId);
      await _markMlKitReady();
      return output;
    } finally {
      await segmenter.close();
    }
  }

  Future<void> _markMlKitReady() async {
    final root = await getApplicationDocumentsDirectory();
    final marker = File(p.join(root.path, 'kickxkick', _mlkitMarkerFile));
    if (!await marker.exists()) {
      await marker.parent.create(recursive: true);
      await marker.create();
    }
  }

  // ---------------------------------------------------------------------------
  // フラッドフィル（iOS フォールバック・既存ロジック）
  // ---------------------------------------------------------------------------

  Future<String> _removeWithFloodFill(
    String sourcePath,
    int shoeId, {
    required double threshold,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('画像を読み込めませんでした');
    final resized =
        decoded.width > 1400 ? img.copyResize(decoded, width: 1400) : decoded;
    final image = resized.convert(numChannels: 4);
    final borderPixels = <img.Pixel>[];
    final xStep = (image.width ~/ 60).clamp(1, 24);
    final yStep = (image.height ~/ 60).clamp(1, 24);
    for (var x = 0; x < image.width; x += xStep) {
      borderPixels.add(image.getPixel(x, 0));
      borderPixels.add(image.getPixel(x, image.height - 1));
    }
    for (var y = 0; y < image.height; y += yStep) {
      borderPixels.add(image.getPixel(0, y));
      borderPixels.add(image.getPixel(image.width - 1, y));
    }
    double median(List<num> values) {
      values.sort((a, b) => a.compareTo(b));
      return values[values.length ~/ 2].toDouble();
    }
    final r = median(borderPixels.map((pixel) => pixel.r).toList());
    final g = median(borderPixels.map((pixel) => pixel.g).toList());
    final b = median(borderPixels.map((pixel) => pixel.b).toList());
    final width = image.width;
    final height = image.height;
    final visited = Uint8List(width * height);
    final queue = <int>[];
    var head = 0;

    bool isBackground(int x, int y) {
      final pixel = image.getPixel(x, y);
      final distance = sqrt(
        pow(pixel.r - r, 2) + pow(pixel.g - g, 2) + pow(pixel.b - b, 2),
      );
      return distance < threshold;
    }

    void enqueue(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final index = y * width + x;
      if (visited[index] != 0 || !isBackground(x, y)) return;
      visited[index] = 1;
      queue.add(index);
    }

    for (var x = 0; x < width; x++) {
      enqueue(x, 0);
      enqueue(x, height - 1);
    }
    for (var y = 1; y < height - 1; y++) {
      enqueue(0, y);
      enqueue(width - 1, y);
    }

    while (head < queue.length) {
      final index = queue[head++];
      final x = index % width;
      final y = index ~/ width;
      final pixel = image.getPixel(x, y);
      image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
      enqueue(x - 1, y);
      enqueue(x + 1, y);
      enqueue(x, y - 1);
      enqueue(x, y + 1);
    }
    _smoothCutoutEdge(image, visited);
    return await _savePng(image, shoeId);
  }

  // ---------------------------------------------------------------------------
  // 共通ヘルパー
  // ---------------------------------------------------------------------------

  Future<String> _savePng(img.Image image, int shoeId) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'kickxkick', 'stickers'));
    await directory.create(recursive: true);
    final output = p.join(
      directory.path,
      'shoe_${shoeId}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(output).writeAsBytes(Uint8List.fromList(img.encodePng(image)));
    return output;
  }

  void _smoothCutoutEdge(img.Image image, Uint8List backgroundMask) {
    // A binary 0/255 alpha edge creates visible stair steps after scaling.
    // Feather only inward so pixels from the removed background cannot form a
    // colored halo around the sneaker.
    const kernel = <int>[1, 4, 6, 4, 1];
    const fullWeight = 256;
    final width = image.width;
    final height = image.height;
    final edgeAlpha = Uint8List(width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        if (backgroundMask[index] != 0) continue;
        var foregroundWeight = 0;
        for (var ky = -2; ky <= 2; ky++) {
          final sampleY = y + ky;
          if (sampleY < 0 || sampleY >= height) continue;
          for (var kx = -2; kx <= 2; kx++) {
            final sampleX = x + kx;
            if (sampleX < 0 || sampleX >= width) continue;
            if (backgroundMask[sampleY * width + sampleX] == 0) {
              foregroundWeight += kernel[ky + 2] * kernel[kx + 2];
            }
          }
        }
        edgeAlpha[index] =
            ((foregroundWeight * 255) / fullWeight).round().clamp(0, 255);
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        if (backgroundMask[index] != 0) continue;
        final alpha = edgeAlpha[index];
        if (alpha == 255) continue;
        final pixel = image.getPixel(x, y);
        image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ブラシ編集（変更なし）
  // ---------------------------------------------------------------------------

  Future<void> applyBrushEdits({
    required String originalPath,
    required String cutoutPath,
    required List<CutoutBrushStroke> strokes,
  }) async {
    final cutout = img.decodeImage(await File(cutoutPath).readAsBytes());
    final source = img.decodeImage(await File(originalPath).readAsBytes());
    if (cutout == null || source == null) {
      throw StateError('画像を読み込めませんでした');
    }
    final original =
        source.width == cutout.width && source.height == cutout.height
            ? source
            : img.copyResize(source, width: cutout.width, height: cutout.height);
    for (final stroke in strokes) {
      final radius = (stroke.size * cutout.width).round().clamp(1, 200);
      if (stroke.fill && stroke.points.length >= 3) {
        _fillEnclosedArea(cutout, original, stroke);
      }
      final points = <CutoutBrushPoint>[];
      for (var index = 0; index < stroke.points.length; index++) {
        final point = stroke.points[index];
        if (index == 0) {
          points.add(point);
          continue;
        }
        final previous = stroke.points[index - 1];
        final dx = (point.x - previous.x) * cutout.width;
        final dy = (point.y - previous.y) * cutout.height;
        final distance = sqrt(dx * dx + dy * dy);
        final steps = (distance / max(1, radius * .45)).ceil();
        for (var step = 1; step <= steps; step++) {
          final t = step / steps;
          points.add(CutoutBrushPoint(
            previous.x + (point.x - previous.x) * t,
            previous.y + (point.y - previous.y) * t,
          ));
        }
      }
      for (final point in points) {
        final cx = (point.x * cutout.width).round();
        final cy = (point.y * cutout.height).round();
        for (var y = cy - radius; y <= cy + radius; y++) {
          if (y < 0 || y >= cutout.height) continue;
          for (var x = cx - radius; x <= cx + radius; x++) {
            if (x < 0 || x >= cutout.width) continue;
            final dx = x - cx;
            final dy = y - cy;
            if (dx * dx + dy * dy > radius * radius) continue;
            final pixel = original.getPixel(x, y);
            cutout.setPixelRgba(
              x,
              y,
              pixel.r,
              pixel.g,
              pixel.b,
              stroke.erase ? 0 : 255,
            );
          }
        }
      }
    }
    await File(cutoutPath)
        .writeAsBytes(Uint8List.fromList(img.encodePng(cutout)));
  }

  void _fillEnclosedArea(
    img.Image cutout,
    img.Image original,
    CutoutBrushStroke stroke,
  ) {
    final xs = stroke.points.map((point) => point.x);
    final ys = stroke.points.map((point) => point.y);
    final minX =
        (xs.reduce(min) * cutout.width).floor().clamp(0, cutout.width - 1);
    final maxX =
        (xs.reduce(max) * cutout.width).ceil().clamp(0, cutout.width - 1);
    final minY =
        (ys.reduce(min) * cutout.height).floor().clamp(0, cutout.height - 1);
    final maxY =
        (ys.reduce(max) * cutout.height).ceil().clamp(0, cutout.height - 1);
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final px = (x + .5) / cutout.width;
        final py = (y + .5) / cutout.height;
        var inside = false;
        for (var i = 0, j = stroke.points.length - 1;
            i < stroke.points.length;
            j = i++) {
          final a = stroke.points[i];
          final b = stroke.points[j];
          final crosses = (a.y > py) != (b.y > py) &&
              px < (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x;
          if (crosses) inside = !inside;
        }
        if (!inside) continue;
        final pixel = original.getPixel(x, y);
        cutout.setPixelRgba(
          x,
          y,
          pixel.r,
          pixel.g,
          pixel.b,
          stroke.erase ? 0 : 255,
        );
      }
    }
  }
}

class CutoutBrushPoint {
  const CutoutBrushPoint(this.x, this.y);
  final double x;
  final double y;
}

class CutoutBrushStroke {
  const CutoutBrushStroke({
    required this.erase,
    required this.size,
    required this.points,
    this.fill = false,
  });
  final bool erase;
  final double size;
  final List<CutoutBrushPoint> points;
  final bool fill;
}
