import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 切り抜き処理の結果（切り抜き画像パス・マスクパス・設定値）
class CutoutResult {
  const CutoutResult({
    required this.cutoutPath,
    this.maskPath,
    required this.threshold,
    required this.engine,
    this.smoothing = 50,
    this.antialiasing = 50,
    this.offsetXFrac = 0,
    this.offsetYFrac = 0,
    this.widthFrac = 1,
    this.heightFrac = 1,
  });

  final String cutoutPath;
  final String? maskPath;
  final double threshold;
  final String engine;
  final double smoothing;
  final double antialiasing;

  /// クロップ位置・範囲（元画像に対する 0〜1 の割合）。クロップなしなら (0, 0, 1, 1)。
  final double offsetXFrac;
  final double offsetYFrac;
  final double widthFrac;
  final double heightFrac;
}

class BackgroundRemovalService {
  static const _mlkitMarkerFile = '.mlkit_ready';

  /// ソフトマット用のランプ幅（ML Kitの確信度は0〜1）。
  /// しきい値の前後この幅の範囲で、アルファをなだらかに0→255へ遷移させる。
  static const _confidenceRampHalfWidth = 0.08;

  /// フラッドフィル用のランプ幅の比率（しきい値に対する割合）。
  /// 色距離はピクセル値のスケールなので、しきい値に比例させて幅を決める。
  static const _floodFillRampRatio = 0.15;

  /// 囲み切り抜きモードで、しきい値を靴寄り/背景寄りにずらす比率。
  /// 「背景を消す」は+30%（背景寄りに広く判定）、「靴を戻す」は-30%（靴寄りに狭く判定）。
  static const _enclosedBiasRatio = 0.3;

  /// Android + ML Kit の初回実行でモデルDLが必要かどうかを返す
  Future<bool> needsModelDownload() async {
    if (!Platform.isAndroid) return false;
    final root = await getApplicationDocumentsDirectory();
    final marker = File(p.join(root.path, 'kickxkick', _mlkitMarkerFile));
    return !await marker.exists();
  }

  /// 背景除去のエントリポイント。CutoutResult を返す。
  /// Android: ML Kit Subject Segmentation → 失敗時はフラッドフィルにフォールバック
  /// iOS: フラッドフィルのみ
  Future<CutoutResult> removeEdgeBackground(
    String sourcePath,
    int shoeId, {
    double threshold = 90,
    double smoothing = 50,
    double antialiasing = 50,
  }) async {
    if (Platform.isAndroid) {
      try {
        return await _removeWithMlKit(
          sourcePath, shoeId,
          threshold: threshold,
          smoothing: smoothing,
          antialiasing: antialiasing,
        );
      } catch (e, stackTrace) {
        debugPrint('[BackgroundRemovalService] ML Kit failed, falling back to floodfill: $e');
        debugPrintStack(stackTrace: stackTrace);
        return await _removeWithFloodFill(
          sourcePath, shoeId,
          threshold: threshold,
          smoothing: smoothing,
          antialiasing: antialiasing,
        );
      }
    }
    return _removeWithFloodFill(
      sourcePath, shoeId,
      threshold: threshold,
      smoothing: smoothing,
      antialiasing: antialiasing,
    );
  }

  // ---------------------------------------------------------------------------
  // ML Kit Subject Segmentation (Android)
  // ---------------------------------------------------------------------------

  Future<CutoutResult> _removeWithMlKit(
    String sourcePath,
    int shoeId, {
    required double threshold,
    double smoothing = 50,
    double antialiasing = 50,
  }) async {
    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: false,
        enableForegroundConfidenceMask: true,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );
    try {
      final result = await segmenter.processImage(
        InputImage.fromFilePath(sourcePath),
      );
      final confidenceList = result.foregroundConfidenceMask;
      if (confidenceList == null) throw StateError('セグメンテーションマスクを取得できませんでした');

      // 出力画像を 1400px 以内にリサイズ
      final bytes = await File(sourcePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw StateError('画像を読み込めませんでした');
      final resized =
          decoded.width > 1400 ? img.copyResize(decoded, width: 1400) : decoded;
      final image = resized.convert(numChannels: 4);

      // 0.0.3 API: foregroundConfidenceMask は List<double>（幅・高さなし）
      // マスクは元画像と同じ解像度で返されるため decoded のサイズを使う
      final maskW = decoded.width;
      final maskH = decoded.height;
      final outW = image.width;
      final outH = image.height;
      final confidences = Float32List.fromList(confidenceList);

      // 既存のスライダー値 (20-220) を確信度カットオフ (0.05-0.95) に変換
      // 低い値 → 前景を多く残す / 高い値 → より積極的に除去
      final cutoff = (threshold / 220.0).clamp(0.05, 0.95);

      // ソフトマット: 確信度を二値化せず、双線形補間でなめらかにサンプリングした上で
      // しきい値付近をなだらかにアルファへ変換する（境界のギザギザを根本から防ぐ）。
      for (var y = 0; y < outH; y++) {
        for (var x = 0; x < outW; x++) {
          final fx = x * maskW / outW;
          final fy = y * maskH / outH;
          final confidence = _bilinearSample(
            fx, fy, maskW, maskH,
            (mx, my) => confidences[my * maskW + mx],
          );
          final alpha = _confidenceToAlpha(confidence, cutoff, _confidenceRampHalfWidth);
          final pixel = image.getPixel(x, y);
          image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
        }
      }

      _applyAntialiasing(image, antialiasing);
      _smoothCutoutEdge(image, smoothing);
      final crop = _cropToOpaqueBounds(image);
      final cutoutPath = await _savePng(crop.image, shoeId);
      final maskPath = await _saveMaskPng(confidences, maskW, maskH, shoeId);
      await _markMlKitReady();
      return CutoutResult(
        cutoutPath: cutoutPath,
        maskPath: maskPath,
        threshold: threshold,
        engine: 'mlkit',
        smoothing: smoothing,
        antialiasing: antialiasing,
        offsetXFrac: crop.offsetXFrac,
        offsetYFrac: crop.offsetYFrac,
        widthFrac: crop.widthFrac,
        heightFrac: crop.heightFrac,
      );
    } finally {
      await segmenter.close();
    }
  }

  Future<String> _saveMaskPng(
    Float32List confidences,
    int maskW,
    int maskH,
    int shoeId,
  ) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'kickxkick', 'masks'));
    await directory.create(recursive: true);
    final output = p.join(
      directory.path,
      'shoe_${shoeId}_${DateTime.now().millisecondsSinceEpoch}_mask.png',
    );
    final maskImage = img.Image(width: maskW, height: maskH);
    for (var y = 0; y < maskH; y++) {
      for (var x = 0; x < maskW; x++) {
        final v = (confidences[y * maskW + x] * 255).round().clamp(0, 255);
        maskImage.setPixelRgba(x, y, v, v, v, 255);
      }
    }
    await File(output).writeAsBytes(Uint8List.fromList(img.encodePng(maskImage)));
    return output;
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

  Future<CutoutResult> _removeWithFloodFill(
    String sourcePath,
    int shoeId, {
    required double threshold,
    double smoothing = 50,
    double antialiasing = 50,
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

    double colorDistance(int x, int y) {
      final pixel = image.getPixel(x, y);
      return sqrt(
        pow(pixel.r - r, 2) + pow(pixel.g - g, 2) + pow(pixel.b - b, 2),
      );
    }

    void enqueue(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final index = y * width + x;
      if (visited[index] != 0 || colorDistance(x, y) >= threshold) return;
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
      enqueue(x - 1, y);
      enqueue(x + 1, y);
      enqueue(x, y - 1);
      enqueue(x, y + 1);
    }

    // ソフトマット: BFSで背景と確定した画素はアルファ0、それ以外は色距離を
    // しきい値付近でなだらかにアルファへ変換する（境界のギザギザを根本から防ぐ）。
    final rampHalfWidth = threshold * _floodFillRampRatio;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = image.getPixel(x, y);
        if (visited[index] != 0) {
          image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
          continue;
        }
        final alpha = _distanceToAlpha(colorDistance(x, y), threshold, rampHalfWidth);
        image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
      }
    }
    _applyAntialiasing(image, antialiasing);
    _smoothCutoutEdge(image, smoothing);
    final crop = _cropToOpaqueBounds(image);
    return CutoutResult(
      cutoutPath: await _savePng(crop.image, shoeId),
      maskPath: null,
      threshold: threshold,
      engine: 'floodfill',
      smoothing: smoothing,
      antialiasing: antialiasing,
      offsetXFrac: crop.offsetXFrac,
      offsetYFrac: crop.offsetYFrac,
      widthFrac: crop.widthFrac,
      heightFrac: crop.heightFrac,
    );
  }

  // ---------------------------------------------------------------------------
  // 共通ヘルパー
  // ---------------------------------------------------------------------------

  /// 不透明ピクセル（アルファ値 > 0）の外接矩形を計算し、各辺に8%のマージンを
  /// 加えてクロップする。画像端を超える場合はクランプする。
  /// 不透明ピクセルが1つもなければクロップせず (0, 0, 1, 1) を返す。
  ({img.Image image, double offsetXFrac, double offsetYFrac, double widthFrac, double heightFrac})
      _cropToOpaqueBounds(img.Image image) {
    final width = image.width;
    final height = image.height;
    var minX = width, minY = height, maxX = -1, maxY = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (image.getPixel(x, y).a > 0) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < minX || maxY < minY) {
      return (image: image, offsetXFrac: 0, offsetYFrac: 0, widthFrac: 1, heightFrac: 1);
    }
    final boxW = maxX - minX + 1;
    final boxH = maxY - minY + 1;
    final marginX = (boxW * 0.08).round();
    final marginY = (boxH * 0.08).round();
    final left = (minX - marginX).clamp(0, width - 1);
    final top = (minY - marginY).clamp(0, height - 1);
    final right = (maxX + marginX).clamp(0, width - 1);
    final bottom = (maxY + marginY).clamp(0, height - 1);
    final cropW = right - left + 1;
    final cropH = bottom - top + 1;
    final cropped = img.copyCrop(image, x: left, y: top, width: cropW, height: cropH);
    return (
      image: cropped,
      offsetXFrac: left / width,
      offsetYFrac: top / height,
      widthFrac: cropW / width,
      heightFrac: cropH / height,
    );
  }

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

  /// 双線形補間で(fx, fy)地点の値をサンプリングする（最近傍よりなめらか）。
  double _bilinearSample(
    double fx,
    double fy,
    int sourceW,
    int sourceH,
    double Function(int x, int y) getValue,
  ) {
    final x0 = fx.floor().clamp(0, sourceW - 1);
    final y0 = fy.floor().clamp(0, sourceH - 1);
    final x1 = (x0 + 1).clamp(0, sourceW - 1);
    final y1 = (y0 + 1).clamp(0, sourceH - 1);
    final tx = (fx - x0).clamp(0.0, 1.0);
    final ty = (fy - y0).clamp(0.0, 1.0);
    final c00 = getValue(x0, y0);
    final c10 = getValue(x1, y0);
    final c01 = getValue(x0, y1);
    final c11 = getValue(x1, y1);
    final top = c00 + (c10 - c00) * tx;
    final bottom = c01 + (c11 - c01) * tx;
    return top + (bottom - top) * ty;
  }

  /// 確信度(0〜1)を、しきい値(cutoff)付近でなだらかに0〜255へ変換する（ソフトマット）。
  /// ハードな二値化を避け、モデルの確信度の勾配をそのままアルファ値に反映する。
  int _confidenceToAlpha(double confidence, double cutoff, double rampHalfWidth) {
    final lower = cutoff - rampHalfWidth;
    final upper = cutoff + rampHalfWidth;
    if (confidence <= lower) return 0;
    if (confidence >= upper) return 255;
    final t = (confidence - lower) / (upper - lower);
    final smoothed = t * t * (3 - 2 * t); // smoothstep
    return (smoothed * 255).round().clamp(0, 255);
  }

  /// 背景色との距離(小さいほど背景寄り)を、しきい値付近でなだらかにアルファへ変換する。
  /// フラッドフィル用（distanceが大きいほど前景寄り＝アルファ高）。
  int _distanceToAlpha(double distance, double threshold, double rampHalfWidth) {
    final lower = threshold - rampHalfWidth;
    final upper = threshold + rampHalfWidth;
    if (distance <= lower) return 0;
    if (distance >= upper) return 255;
    final t = (distance - lower) / (upper - lower);
    final smoothed = t * t * (3 - 2 * t); // smoothstep
    return (smoothed * 255).round().clamp(0, 255);
  }

  /// アンチエイリアス（3×3カーネル）- ソフトマットの境界(0<アルファ<255)だけを対象に、
  /// 周囲のアルファ値そのものとブレンドして1ピクセル単位の粗さをさらに整える。
  void _applyAntialiasing(img.Image image, double strength) {
    if (strength <= 0) return;
    final t = (strength / 100.0).clamp(0.0, 1.0);
    const kernel = <int>[1, 2, 1];
    const fullWeight = 16;
    final width = image.width;
    final height = image.height;
    final original = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        original[y * width + x] = image.getPixel(x, y).a.toInt();
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final current = original[index];
        if (current == 0 || current == 255) continue;
        var weightedSum = 0;
        for (var ky = -1; ky <= 1; ky++) {
          final sampleY = (y + ky).clamp(0, height - 1);
          for (var kx = -1; kx <= 1; kx++) {
            final sampleX = (x + kx).clamp(0, width - 1);
            weightedSum += original[sampleY * width + sampleX] * kernel[ky + 1] * kernel[kx + 1];
          }
        }
        final blurred = (weightedSum / fullWeight).round().clamp(0, 255);
        final blended = (current * (1 - t) + blurred * t).round().clamp(0, 255);
        final pixel = image.getPixel(x, y);
        image.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), blended);
      }
    }
  }

  /// エッジスムージング（5×5 Binomial kernel）- ソフトマットの境界だけを対象に、
  /// より広い範囲のアルファ値とブレンドして数ピクセル範囲のガタつきを整える。
  void _smoothCutoutEdge(img.Image image, double strength) {
    if (strength <= 0) return;
    final t = (strength / 100.0).clamp(0.0, 1.0);
    const kernel = <int>[1, 4, 6, 4, 1];
    const fullWeight = 256;
    final width = image.width;
    final height = image.height;
    final original = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        original[y * width + x] = image.getPixel(x, y).a.toInt();
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final current = original[index];
        if (current == 0 || current == 255) continue;
        var weightedSum = 0;
        for (var ky = -2; ky <= 2; ky++) {
          final sampleY = (y + ky).clamp(0, height - 1);
          for (var kx = -2; kx <= 2; kx++) {
            final sampleX = (x + kx).clamp(0, width - 1);
            weightedSum += original[sampleY * width + sampleX] * kernel[ky + 2] * kernel[kx + 2];
          }
        }
        final blurred = (weightedSum / fullWeight).round().clamp(0, 255);
        final blended = (current * (1 - t) + blurred * t).round().clamp(0, 255);
        final pixel = image.getPixel(x, y);
        image.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), blended);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // マスク再利用による高速再生成（ML Kit 再実行不要）
  // ---------------------------------------------------------------------------

  /// 保存済みマスク画像（グレースケール PNG）と設定値から切り抜きを再生成する。
  /// ML Kit の再実行なしに threshold / smoothing / antialiasing だけを再適用できる。
  Future<CutoutResult> regenerateFromMask({
    required String sourcePath,
    required String maskPath,
    required int shoeId,
    required double threshold,
    double smoothing = 50,
    double antialiasing = 50,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('元画像を読み込めませんでした');
    final resized =
        decoded.width > 1400 ? img.copyResize(decoded, width: 1400) : decoded;
    final image = resized.convert(numChannels: 4);

    final maskBytes = await File(maskPath).readAsBytes();
    final maskImage = img.decodeImage(maskBytes);
    if (maskImage == null) throw StateError('マスク画像を読み込めませんでした');

    final maskW = maskImage.width;
    final maskH = maskImage.height;
    final outW = image.width;
    final outH = image.height;

    // threshold (20-220) → 確信度カットオフ (0.05-0.95) — _removeWithMlKit と同じ変換
    final cutoff = (threshold / 220.0).clamp(0.05, 0.95);

    // ソフトマット: 確信度を二値化せず、双線形補間でなめらかにサンプリングした上で
    // しきい値付近をなだらかにアルファへ変換する（_removeWithMlKit と同じ考え方）。
    for (var y = 0; y < outH; y++) {
      for (var x = 0; x < outW; x++) {
        final fx = x * maskW / outW;
        final fy = y * maskH / outH;
        // マスクは R チャンネルに確信度 * 255 が格納されている
        final confidence = _bilinearSample(
          fx, fy, maskW, maskH,
          (mx, my) => maskImage.getPixel(mx, my).r / 255.0,
        );
        final alpha = _confidenceToAlpha(confidence, cutoff, _confidenceRampHalfWidth);
        final pixel = image.getPixel(x, y);
        image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
      }
    }

    _applyAntialiasing(image, antialiasing);
    _smoothCutoutEdge(image, smoothing);

    final crop = _cropToOpaqueBounds(image);
    return CutoutResult(
      cutoutPath: await _savePng(crop.image, shoeId),
      maskPath: maskPath,
      threshold: threshold,
      engine: 'mlkit',
      smoothing: smoothing,
      antialiasing: antialiasing,
      offsetXFrac: crop.offsetXFrac,
      offsetYFrac: crop.offsetYFrac,
      widthFrac: crop.widthFrac,
      heightFrac: crop.heightFrac,
    );
  }

  // ---------------------------------------------------------------------------
  // ブラシ編集
  // ---------------------------------------------------------------------------

  Future<void> applyBrushEdits({
    required String originalPath,
    required String cutoutPath,
    required List<CutoutBrushStroke> strokes,
    double offsetXFrac = 0,
    double offsetYFrac = 0,
    double widthFrac = 1,
    double heightFrac = 1,
  }) async {
    final cutout = img.decodeImage(await File(cutoutPath).readAsBytes());
    final source = img.decodeImage(await File(originalPath).readAsBytes());
    if (cutout == null || source == null) {
      throw StateError('画像を読み込めませんでした');
    }
    // クロップ（元画像のうちcutoutに対応する範囲を切り出す）→ リサイズ の2段階で
    // originalをcutoutと同じピクセルグリッドに揃える。offsetXFrac等が未指定（0,0,1,1）
    // なら従来通りクロップなしでリサイズのみになる。
    final cropX = (offsetXFrac * source.width).round().clamp(0, source.width - 1);
    final cropY = (offsetYFrac * source.height).round().clamp(0, source.height - 1);
    final cropW = (widthFrac * source.width).round().clamp(1, source.width - cropX);
    final cropH = (heightFrac * source.height).round().clamp(1, source.height - cropY);
    final croppedSource =
        (cropX == 0 && cropY == 0 && cropW == source.width && cropH == source.height)
            ? source
            : img.copyCrop(source, x: cropX, y: cropY, width: cropW, height: cropH);
    final original =
        croppedSource.width == cutout.width && croppedSource.height == cutout.height
            ? croppedSource
            : img.copyResize(croppedSource, width: cutout.width, height: cutout.height);
    // 囲み切り抜きモードの背景色サンプリングは、使う時だけ計算する（複数ストロークで使い回す）。
    ({double r, double g, double b})? enclosedBackgroundRef;
    for (final stroke in strokes) {
      if (stroke.enclosedRejudge && stroke.points.length >= 3) {
        enclosedBackgroundRef ??= _estimateBackgroundColor(original);
        _rejudgeEnclosedArea(cutout, original, stroke, enclosedBackgroundRef);
        continue;
      }
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

  /// 画像の端（枠）の色の中央値から、背景色の目安を推定する。
  /// _removeWithFloodFill と同じサンプリング方法を、ブラシ編集時の
  /// 「元の写真」（原則、切り抜き範囲の端は背景寄りになっている）に適用する。
  ({double r, double g, double b}) _estimateBackgroundColor(img.Image image) {
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
    return (
      r: median(borderPixels.map((pixel) => pixel.r).toList()),
      g: median(borderPixels.map((pixel) => pixel.g).toList()),
      b: median(borderPixels.map((pixel) => pixel.b).toList()),
    );
  }

  /// 囲み切り抜きモード: なぞった輪の内側だけ、元の写真の色を背景色と比較して
  /// 靴か背景かを判定し直す。しきい値をerase/restoreの方向にずらすことで、
  /// 「背景を消す」は背景寄りに、「靴を戻す」は靴寄りに判定を倒す。
  void _rejudgeEnclosedArea(
    img.Image cutout,
    img.Image original,
    CutoutBrushStroke stroke,
    ({double r, double g, double b}) backgroundRef,
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
    final biasedThreshold = stroke.erase
        ? stroke.threshold * (1 + _enclosedBiasRatio)
        : stroke.threshold * (1 - _enclosedBiasRatio);
    final rampHalfWidth = biasedThreshold * _floodFillRampRatio;
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
        final distance = sqrt(
          pow(pixel.r - backgroundRef.r, 2) +
              pow(pixel.g - backgroundRef.g, 2) +
              pow(pixel.b - backgroundRef.b, 2),
        );
        final alpha = _distanceToAlpha(distance, biasedThreshold, rampHalfWidth);
        cutout.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
      }
    }
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
    this.enclosedRejudge = false,
    this.threshold = 90,
  });
  final bool erase;
  final double size;
  final List<CutoutBrushPoint> points;
  final bool fill;

  /// true の場合、なぞった輪の内側を単純に塗るのではなく、元の写真の色を
  /// 背景色と比較して靴か背景かを判定し直す「囲み切り抜きモード」として扱う。
  final bool enclosedRejudge;

  /// 囲み切り抜きモードで判定の基準にするしきい値（生成時のスライダー値）。
  final double threshold;
}
