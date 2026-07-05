import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/background_removal_service.dart'
    show
        BackgroundRemovalService,
        CutoutResult,
        CutoutBrushStroke,
        CutoutBrushPoint;

class CutoutAdjustmentScreen extends StatefulWidget {
  const CutoutAdjustmentScreen({
    super.key,
    required this.sourcePath,
    required this.shoeId,
    this.initialCutoutPath,
    this.initialCropOffsetXFrac = 0,
    this.initialCropOffsetYFrac = 0,
    this.initialCropWidthFrac = 1,
    this.initialCropHeightFrac = 1,
  });

  final String sourcePath;
  final int shoeId;
  final String? initialCutoutPath;

  /// 既存のクロップ位置・範囲（元画像に対する 0〜1 の割合）。
  /// 既存のPhoto/StickerAssetを再編集する場合に渡す。新規生成時は指定不要。
  final double initialCropOffsetXFrac;
  final double initialCropOffsetYFrac;
  final double initialCropWidthFrac;
  final double initialCropHeightFrac;

  @override
  State<CutoutAdjustmentScreen> createState() => _CutoutAdjustmentScreenState();
}

class _CutoutAdjustmentScreenState extends State<CutoutAdjustmentScreen> {
  double _threshold = 20;
  double _smoothing = 0;
  double _antialiasing = 0;
  String? _previewPath;
  String? _maskPath;
  String _cutoutEngine = 'floodfill';
  late double _cropOffsetXFrac;
  late double _cropOffsetYFrac;
  late double _cropWidthFrac;
  late double _cropHeightFrac;
  Uint8List? _basePreviewBytes;
  int _previewRevision = 0;
  bool _processing = false;
  _EditMode _mode = _EditMode.move;
  double _brushSize = 0.012;
  // 囲み切り抜きモード（デフォルトON）。背景を消す/靴を戻すそれぞれで個別に切り替えられる。
  bool _enclosedModeErase = true;
  bool _enclosedModeRestore = true;
  final List<CutoutBrushStroke> _strokes = [];
  final List<CutoutBrushStroke> _redo = [];
  List<CutoutBrushPoint>? _activePoints;
  Offset? _brushPosition;
  List<Offset> _outlinePoints = const [];
  List<List<Offset>> _outlineRegions = const [];
  double _previewAspect = 1;
  bool _adjusting = false;
  bool _rendering = false;
  final TransformationController _transformationController =
      TransformationController();

  // −/+ボタンの長押し連続増減用タイマー
  Timer? _stepTimer;

  // 囲み切り抜きモードとして扱う最小サイズ（ブラシの太さの何倍以上か）。
  // これより小さい輪は「囲み」と呼べないため、通常モードにフォールバックする。
  static const _enclosedMinSizeFactor = 3.0;

  @override
  void dispose() {
    _stepTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cropOffsetXFrac = widget.initialCropOffsetXFrac;
    _cropOffsetYFrac = widget.initialCropOffsetYFrac;
    _cropWidthFrac = widget.initialCropWidthFrac;
    _cropHeightFrac = widget.initialCropHeightFrac;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPath = widget.initialCutoutPath;
      if (initialPath != null && File(initialPath).existsSync()) {
        _loadExistingCutout(initialPath);
      } else {
        _generate();
      }
    });
  }

  Future<void> _loadExistingCutout(String sourceCutoutPath) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final sourceFile = File(sourceCutoutPath);
      final bytes = await sourceFile.readAsBytes();
      final separator = Platform.pathSeparator;
      final parent = sourceFile.parent.path;
      final path =
          '$parent${separator}shoe_${widget.shoeId}_edit_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes, flush: true);
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw StateError('画像を読み込めませんでした');
      if (!mounted) return;
      setState(() {
        _previewPath = path;
        _basePreviewBytes = bytes;
        _previewAspect = decoded.width / decoded.height;
        _previewRevision++;
        _outlinePoints = const [];
        _outlineRegions = const [];
        _strokes.clear();
        _redo.clear();
        _adjusting = true;
        _mode = _EditMode.move;
        _transformationController.value = Matrix4.identity();
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _generate() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (mounted && await BackgroundRemovalService().needsModelDownload()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('初回のみAIモデルの準備が必要なため、少し時間がかかります'),
            duration: Duration(seconds: 8),
          ),
        );
      }
      final result = await BackgroundRemovalService().removeEdgeBackground(
        widget.sourcePath,
        widget.shoeId,
        threshold: _threshold,
        smoothing: _smoothing,
        antialiasing: _antialiasing,
      );
      final outline = await _detectOutline(result.cutoutPath);
      final baseBytes = await File(result.cutoutPath).readAsBytes();
      if (mounted) {
        setState(() {
          _previewPath = result.cutoutPath;
          _maskPath = result.maskPath;
          _cutoutEngine = result.engine;
          _cropOffsetXFrac = result.offsetXFrac;
          _cropOffsetYFrac = result.offsetYFrac;
          _cropWidthFrac = result.widthFrac;
          _cropHeightFrac = result.heightFrac;
          _basePreviewBytes = baseBytes;
          _previewRevision++;
          _outlinePoints = outline;
          _strokes.clear();
          _redo.clear();
          _adjusting = false;
          _mode = _EditMode.move;
          _transformationController.value = Matrix4.identity();
        });
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _startStep(double Function(double) update, VoidCallback? onStop) {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {});
    });
  }

  void _stopStep() {
    _stepTimer?.cancel();
    _stepTimer = null;
  }

  Widget _buildStepButton({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
    VoidCallback? onChangeEnd,
  }) {
    void press() {
      final next = (value + step).clamp(min, max);
      onChanged(next);
    }

    return GestureDetector(
      onTapDown: (_) =>
          setState(() => onChanged((value + step).clamp(min, max))),
      onTapUp: (_) {
        _stopStep();
        onChangeEnd?.call();
      },
      onTapCancel: _stopStep,
      onLongPressStart: (_) {
        _stepTimer?.cancel();
        _stepTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
          final next = (value + step).clamp(min, max);
          if (mounted) setState(() => onChanged(next));
        });
      },
      onLongPressEnd: (_) {
        _stopStep();
        onChangeEnd?.call();
      },
      onLongPressCancel: _stopStep,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    VoidCallback? onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          _buildStepButton(
            icon: Icons.remove,
            value: value,
            min: min,
            max: max,
            step: -(max - min) / 100,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: _processing ? null : onChanged,
              onChangeEnd: onChangeEnd == null ? null : (_) => onChangeEnd(),
            ),
          ),
          _buildStepButton(
            icon: Icons.add,
            value: value,
            min: min,
            max: max,
            step: (max - min) / 100,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${value.round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'キャンセル',
          onPressed: _onCancel,
        ),
        title: const Text('切り抜きを微調整'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildModeIndicator(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const CustomPaint(
                          painter: _TransparencyCheckerPainter(),
                        ),
                        Center(
                          child: _processing
                              ? const CircularProgressIndicator()
                              : _previewPath == null
                              ? const Text('切り抜きを生成できませんでした')
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final editor = GestureDetector(
                                      onTapUp: _adjusting
                                          ? null
                                          : (details) => _restoreOutlineAt(
                                              details.localPosition,
                                              constraints,
                                            ),
                                      onPanStart:
                                          !_adjusting || _mode == _EditMode.move
                                          ? null
                                          : (details) {
                                              _redo.clear();
                                              _activePoints = [
                                                _normalize(
                                                  details.localPosition,
                                                  constraints,
                                                ),
                                              ];
                                              _brushPosition =
                                                  details.localPosition;
                                            },
                                      onPanUpdate:
                                          !_adjusting || _mode == _EditMode.move
                                          ? null
                                          : (details) {
                                              setState(
                                                () => _activePoints!.add(
                                                  _normalize(
                                                    details.localPosition,
                                                    constraints,
                                                  ),
                                                ),
                                              );
                                              _brushPosition =
                                                  details.localPosition;
                                            },
                                      onPanEnd:
                                          !_adjusting || _mode == _EditMode.move
                                          ? null
                                          : (_) async {
                                              final points = List.of(
                                                _activePoints!,
                                              );
                                              final closesShape =
                                                  points.length >= 4 &&
                                                  _pointDistance(
                                                        points.first,
                                                        points.last,
                                                      ) <
                                                      _brushSize * 2.5;
                                              final enclosedToggleOn =
                                                  _mode == _EditMode.erase
                                                  ? _enclosedModeErase
                                                  : _enclosedModeRestore;
                                              final closedPoints =
                                                  _closePolygon(points);
                                              final bbox = _boundingBoxSize(
                                                closedPoints,
                                              );
                                              final bigEnough =
                                                  math.min(bbox.$1, bbox.$2) >=
                                                  _brushSize *
                                                      _enclosedMinSizeFactor;
                                              final useEnclosedMode =
                                                  enclosedToggleOn &&
                                                  bigEnough &&
                                                  closedPoints.length >= 3;
                                              final stroke = useEnclosedMode
                                                  ? CutoutBrushStroke(
                                                      erase:
                                                          _mode ==
                                                          _EditMode.erase,
                                                      size: _brushSize,
                                                      points: closedPoints,
                                                      enclosedRejudge: true,
                                                      threshold: _threshold,
                                                    )
                                                  : CutoutBrushStroke(
                                                      erase:
                                                          _mode ==
                                                          _EditMode.erase,
                                                      size: _brushSize,
                                                      points: points,
                                                      fill:
                                                          closesShape &&
                                                          _mode ==
                                                              _EditMode.erase,
                                                    );
                                              setState(() {
                                                _strokes.add(stroke);
                                                _activePoints = null;
                                                _brushPosition = null;
                                              });
                                              await _renderBrushEdits();
                                            },
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(
                                            File(_previewPath!),
                                            key: ValueKey(_previewRevision),
                                            fit: BoxFit.contain,
                                          ),
                                          IgnorePointer(
                                            child: CustomPaint(
                                              painter: _OutlinePainter(
                                                points: _adjusting
                                                    ? const []
                                                    : _outlinePoints,
                                                imageAspect: _previewAspect,
                                              ),
                                            ),
                                          ),
                                          CustomPaint(
                                            painter: _StrokePainter(
                                              strokes: const [],
                                              activePoints: _activePoints,
                                              erase: _mode == _EditMode.erase,
                                              brushSize: _brushSize,
                                              imageAspect: _previewAspect,
                                            ),
                                          ),
                                          if (_brushPosition != null &&
                                              _mode != _EditMode.move)
                                            _buildMagnifier(constraints),
                                          if (_rendering)
                                            Container(
                                              color: Colors.black54,
                                              child: const Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      '画像を更新中…',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                    return InteractiveViewer(
                                      transformationController:
                                          _transformationController,
                                      minScale: 1,
                                      maxScale: 6,
                                      panEnabled:
                                          !_adjusting ||
                                          _mode == _EditMode.move,
                                      child: editor,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_adjusting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SegmentedButton<_EditMode>(
                        segments: const [
                          ButtonSegment(
                            value: _EditMode.move,
                            icon: Icon(Icons.pan_tool_outlined),
                            label: Text('移動'),
                          ),
                          ButtonSegment(
                            value: _EditMode.erase,
                            icon: Icon(Icons.auto_fix_off),
                            label: Text('背景を消す'),
                          ),
                          ButtonSegment(
                            value: _EditMode.restore,
                            icon: Icon(Icons.restore),
                            label: Text('靴を戻す'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (value) =>
                            setState(() => _mode = value.first),
                      ),
                      IconButton(
                        tooltip: 'Undo',
                        onPressed: _strokes.isEmpty
                            ? null
                            : () async {
                                setState(
                                  () => _redo.add(_strokes.removeLast()),
                                );
                                await _renderBrushEdits();
                              },
                        icon: const Icon(Icons.undo),
                      ),
                      IconButton(
                        tooltip: 'Redo',
                        onPressed: _redo.isEmpty
                            ? null
                            : () async {
                                setState(
                                  () => _strokes.add(_redo.removeLast()),
                                );
                                await _renderBrushEdits();
                              },
                        icon: const Icon(Icons.redo),
                      ),
                    ],
                  ),
                ),
              ),
            if (_adjusting && _mode != _EditMode.move)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('ブラシ'),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 0.002,
                        max: 0.08,
                        onChanged: (value) =>
                            setState(() => _brushSize = value),
                      ),
                    ),
                  ],
                ),
              ),
            if (_adjusting && _mode != _EditMode.move)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('囲み切り抜き'),
                    Switch(
                      value: _mode == _EditMode.erase
                          ? _enclosedModeErase
                          : _enclosedModeRestore,
                      onChanged: (value) => setState(() {
                        if (_mode == _EditMode.erase) {
                          _enclosedModeErase = value;
                        } else {
                          _enclosedModeRestore = value;
                        }
                      }),
                    ),
                  ],
                ),
              ),
            // 自動生成モード時の調整パネル開閉バー
            if (!_adjusting) _buildAdjustmentPanelHandle(),
            if (_adjusting)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing
                            ? null
                            : () => setState(() {
                                _adjusting = false;
                                _mode = _EditMode.move;
                                _transformationController.value =
                                    Matrix4.identity();
                              }),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('AI調整に戻る'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _previewPath == null || _processing
                            ? null
                            : () async {
                                setState(() => _processing = true);
                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                    CutoutResult(
                                      cutoutPath: _previewPath!,
                                      maskPath: _maskPath,
                                      threshold: _threshold,
                                      engine: _cutoutEngine,
                                      smoothing: _smoothing,
                                      antialiasing: _antialiasing,
                                      offsetXFrac: _cropOffsetXFrac,
                                      offsetYFrac: _cropOffsetYFrac,
                                      widthFrac: _cropWidthFrac,
                                      heightFrac: _cropHeightFrac,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.check),
                        label: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _generate,
                        icon: const Icon(Icons.refresh),
                        label: const Text('やり直す'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _previewPath == null || _processing
                            ? null
                            : () => setState(() {
                                _adjusting = true;
                                _mode = _EditMode.move;
                                _transformationController.value =
                                    Matrix4.identity();
                              }),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('次へ：微調整する'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentPanelHandle() {
    return GestureDetector(
      onTap: _showAdjustmentPanel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '切り抜き設定を調整',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_up,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustmentPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AdjustmentPanel(
        threshold: _threshold,
        smoothing: _smoothing,
        antialiasing: _antialiasing,
        processing: _processing,
        onThresholdChanged: (v) => setState(() => _threshold = v),
        onSmoothingChanged: (v) => setState(() => _smoothing = v),
        onAntialiasingChanged: (v) => setState(() => _antialiasing = v),
        onGenerate: () {
          Navigator.pop(ctx);
          _generate();
        },
      ),
    );
  }

  CutoutBrushPoint _normalize(Offset position, BoxConstraints constraints) {
    final rect = _imageRect(Size(constraints.maxWidth, constraints.maxHeight));
    return CutoutBrushPoint(
      ((position.dx - rect.left) / rect.width).clamp(0, 1),
      ((position.dy - rect.top) / rect.height).clamp(0, 1),
    );
  }

  double _pointDistance(CutoutBrushPoint a, CutoutBrushPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// 始点と終点が離れている場合、始点を末尾に追加して輪っことして閉じる。
  List<CutoutBrushPoint> _closePolygon(List<CutoutBrushPoint> points) {
    if (points.length < 2) return points;
    final first = points.first;
    final last = points.last;
    if (_pointDistance(first, last) < 0.001) return points;
    return [...points, first];
  }

  /// 点群の外接する四角形の幅・高さ（正規化座標系、0〜1）を返す。
  (double, double) _boundingBoxSize(List<CutoutBrushPoint> points) {
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }
    return (maxX - minX, maxY - minY);
  }

  Future<void> _restoreOutlineAt(
    Offset position,
    BoxConstraints constraints,
  ) async {
    if (_previewPath == null || _outlinePoints.isEmpty) return;
    final normalized = _normalize(position, constraints);
    List<Offset>? selectedRegion;
    var nearestDistance = double.infinity;
    for (final region in _outlineRegions) {
      for (final point in region) {
        final dx = point.dx - normalized.x;
        final dy = point.dy - normalized.y;
        final distance = dx * dx + dy * dy;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          selectedRegion = region;
        }
      }
    }
    if (selectedRegion == null ||
        selectedRegion.length < 3 ||
        nearestDistance > .0036) {
      return;
    }
    final center =
        selectedRegion.reduce((a, b) => a + b) /
        selectedRegion.length.toDouble();
    final polygon = [...selectedRegion]
      ..sort(
        (a, b) => math
            .atan2(a.dy - center.dy, a.dx - center.dx)
            .compareTo(math.atan2(b.dy - center.dy, b.dx - center.dx)),
      );
    setState(() {
      _redo.clear();
      _strokes.add(
        CutoutBrushStroke(
          erase: false,
          size: .002,
          fill: true,
          points: polygon
              .map((point) => CutoutBrushPoint(point.dx, point.dy))
              .toList(),
        ),
      );
    });
    await _renderBrushEdits(refreshOutline: true);
  }

  Future<void> _onCancel() async {
    if (_strokes.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('変更を破棄しますか？'),
          content: const Text('ブラシで加えた変更は保存されません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('続ける'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('破棄して戻る'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    if (mounted) Navigator.pop(context, null);
  }

  Widget _buildModeIndicator(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_adjusting) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: cs.primaryContainer,
        child: Row(
          children: [
            Icon(Icons.edit_outlined, size: 15, color: cs.onPrimaryContainer),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'ブラシ調整モード — 背景が複雑・靴と背景色が似ている写真では自動切り抜きが難しい場合があります。ブラシで手動修正してください。',
                style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: cs.tertiaryContainer,
      child: Row(
        children: [
          Icon(Icons.auto_fix_high, size: 15, color: cs.onTertiaryContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '自動生成モード — 下のパネルで切り抜き強さを調整',
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagnifier(BoxConstraints constraints) {
    final finger = _brushPosition!;
    const magnifierSize = 160.0;
    const margin = 12.0;
    final placeLeft = finger.dx > constraints.maxWidth / 2;
    final placeTop = finger.dy > constraints.maxHeight / 2;
    final center = Offset(
      placeLeft
          ? margin + magnifierSize / 2
          : constraints.maxWidth - margin - magnifierSize / 2,
      placeTop
          ? margin + magnifierSize / 2
          : constraints.maxHeight - margin - magnifierSize / 2,
    );
    return Positioned(
      left: placeLeft ? margin : null,
      right: placeLeft ? null : margin,
      top: placeTop ? margin : null,
      bottom: placeTop ? null : margin,
      child: IgnorePointer(
        child: RawMagnifier(
          size: const Size.square(magnifierSize),
          magnificationScale: 3.0,
          focalPointOffset: finger - center,
          decoration: const MagnifierDecoration(
            shape: CircleBorder(
              side: BorderSide(color: Colors.orange, width: 4),
            ),
            shadows: [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
        ),
      ),
    );
  }

  Future<void> _renderBrushEdits({bool refreshOutline = false}) async {
    final path = _previewPath;
    final baseBytes = _basePreviewBytes;
    if (path == null || baseBytes == null) return;
    if (mounted) setState(() => _rendering = true);
    try {
      await File(path).writeAsBytes(baseBytes, flush: true);
      if (_strokes.isNotEmpty) {
        await BackgroundRemovalService().applyBrushEdits(
          originalPath: widget.sourcePath,
          cutoutPath: path,
          strokes: List.of(_strokes),
          offsetXFrac: _cropOffsetXFrac,
          offsetYFrac: _cropOffsetYFrac,
          widthFrac: _cropWidthFrac,
          heightFrac: _cropHeightFrac,
        );
      }
      await FileImage(File(path)).evict();
      final outline = refreshOutline ? await _detectOutline(path) : null;
      if (mounted) {
        setState(() {
          _previewRevision++;
          if (outline != null) _outlinePoints = outline;
        });
      }
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  Rect _imageRect(Size size) {
    final canvasAspect = size.width / size.height;
    if (_previewAspect > canvasAspect) {
      final height = size.width / _previewAspect;
      return Rect.fromLTWH(0, (size.height - height) / 2, size.width, height);
    }
    final width = size.height * _previewAspect;
    return Rect.fromLTWH((size.width - width) / 2, 0, width, size.height);
  }

  Future<List<Offset>> _detectOutline(String path) async {
    final decoded = img.decodeImage(await File(path).readAsBytes());
    if (decoded == null) return const [];
    _previewAspect = decoded.width / decoded.height;
    final points = <Offset>[];
    final gridPoints = <int, _OutlineGridPoint>{};
    final step = (decoded.width / 160).ceil().clamp(3, 12);
    for (var y = step; y < decoded.height - step; y += step) {
      for (var x = step; x < decoded.width - step; x += step) {
        if (decoded.getPixel(x, y).a < 40) continue;
        final edge =
            decoded.getPixel(x - step, y).a < 40 ||
            decoded.getPixel(x + step, y).a < 40 ||
            decoded.getPixel(x, y - step).a < 40 ||
            decoded.getPixel(x, y + step).a < 40;
        if (edge) {
          final offset = Offset(x / decoded.width, y / decoded.height);
          points.add(offset);
          final gx = x ~/ step;
          final gy = y ~/ step;
          gridPoints[gy * 100000 + gx] = _OutlineGridPoint(gx, gy, offset);
        }
      }
    }
    final remaining = gridPoints.keys.toSet();
    final regions = <List<Offset>>[];
    while (remaining.isNotEmpty) {
      final first = remaining.first;
      remaining.remove(first);
      final queue = <int>[first];
      final region = <Offset>[];
      for (var head = 0; head < queue.length; head++) {
        final current = gridPoints[queue[head]]!;
        region.add(current.offset);
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            if (dx == 0 && dy == 0) continue;
            final neighborKey = (current.gy + dy) * 100000 + current.gx + dx;
            if (remaining.remove(neighborKey)) queue.add(neighborKey);
          }
        }
      }
      if (region.length >= 3) regions.add(region);
    }
    _outlineRegions = regions;
    return points;
  }
}

// ---------------------------------------------------------------------------
// 調整パネル（BottomSheet）
// ---------------------------------------------------------------------------

class _AdjustmentPanel extends StatefulWidget {
  const _AdjustmentPanel({
    required this.threshold,
    required this.smoothing,
    required this.antialiasing,
    required this.processing,
    required this.onThresholdChanged,
    required this.onSmoothingChanged,
    required this.onAntialiasingChanged,
    required this.onGenerate,
  });

  final double threshold;
  final double smoothing;
  final double antialiasing;
  final bool processing;
  final ValueChanged<double> onThresholdChanged;
  final ValueChanged<double> onSmoothingChanged;
  final ValueChanged<double> onAntialiasingChanged;
  final VoidCallback onGenerate;

  @override
  State<_AdjustmentPanel> createState() => _AdjustmentPanelState();
}

class _AdjustmentPanelState extends State<_AdjustmentPanel> {
  late double _threshold;
  late double _smoothing;
  late double _antialiasing;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _threshold = widget.threshold;
    _smoothing = widget.smoothing;
    _antialiasing = widget.antialiasing;
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startLongPress(VoidCallback tick) {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) {
        setState(tick);
      }
    });
  }

  void _stopLongPress() {
    _stepTimer?.cancel();
    _stepTimer = null;
  }

  Widget _buildStepBtn({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
  }) {
    final next = (value + step).clamp(min, max);
    return GestureDetector(
      onTapDown: (_) => setState(() => onChanged(next)),
      onLongPressStart: (_) =>
          _startLongPress(() => onChanged((value + step).clamp(min, max))),
      onLongPressEnd: (_) => _stopLongPress(),
      onLongPressCancel: _stopLongPress,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required VoidCallback onChangeEnd,
    double displayOffset = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          _buildStepBtn(
            icon: Icons.remove,
            value: value,
            min: min,
            max: max,
            step: -(max - min) / 100,
            onChanged: (v) {
              onChanged(v);
              setState(() {});
            },
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: widget.processing
                  ? null
                  : (v) {
                      setState(() => onChanged(v));
                    },
              onChangeEnd: (_) => onChangeEnd(),
            ),
          ),
          _buildStepBtn(
            icon: Icons.add,
            value: value,
            min: min,
            max: max,
            step: (max - min) / 100,
            onChanged: (v) {
              onChanged(v);
              setState(() {});
            },
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${(value - displayOffset).round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '切り抜き設定',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          _buildRow(
            label: '背景除去の強さ',
            value: _threshold,
            min: 20,
            max: 220,
            onChanged: (v) {
              _threshold = v;
              widget.onThresholdChanged(v);
            },
            onChangeEnd: widget.onGenerate,
            displayOffset: 20,
          ),
          _buildRow(
            label: 'スムージング',
            value: _smoothing,
            min: 0,
            max: 100,
            onChanged: (v) {
              _smoothing = v;
              widget.onSmoothingChanged(v);
            },
            onChangeEnd: widget.onGenerate,
          ),
          _buildRow(
            label: 'アンチエイリアス',
            value: _antialiasing,
            min: 0,
            max: 100,
            onChanged: (v) {
              _antialiasing = v;
              widget.onAntialiasingChanged(v);
            },
            onChangeEnd: widget.onGenerate,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.processing ? null : widget.onGenerate,
              icon: const Icon(Icons.refresh),
              label: const Text('この設定で再生成'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 既存ヘルパークラス（変更なし）
// ---------------------------------------------------------------------------

class _OutlineGridPoint {
  const _OutlineGridPoint(this.gx, this.gy, this.offset);
  final int gx;
  final int gy;
  final Offset offset;
}

enum _EditMode { move, erase, restore }

class _TransparencyCheckerPainter extends CustomPainter {
  const _TransparencyCheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 18.0;
    const light = Color(0xFFE8E0D9);
    const dark = Color(0xFF8E8178);
    final paint = Paint();
    for (var y = 0.0; y < size.height; y += tileSize) {
      for (var x = 0.0; x < size.width; x += tileSize) {
        final column = (x / tileSize).floor();
        final row = (y / tileSize).floor();
        paint.color = (column + row).isEven ? light : dark;
        canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TransparencyCheckerPainter oldDelegate) =>
      false;
}

class _OutlinePainter extends CustomPainter {
  const _OutlinePainter({required this.points, required this.imageAspect});
  final List<Offset> points;
  final double imageAspect;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final canvasAspect = size.width / size.height;
    final Rect imageRect;
    if (imageAspect > canvasAspect) {
      final height = size.width / imageAspect;
      imageRect = Rect.fromLTWH(
        0,
        (size.height - height) / 2,
        size.width,
        height,
      );
    } else {
      final width = size.height * imageAspect;
      imageRect = Rect.fromLTWH(
        (size.width - width) / 2,
        0,
        width,
        size.height,
      );
    }
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.85);
    final orange = Paint()..color = Colors.orange;
    for (var index = 0; index < points.length; index += 8) {
      final point = points[index];
      final position = Offset(
        imageRect.left + point.dx * imageRect.width,
        imageRect.top + point.dy * imageRect.height,
      );
      canvas.drawCircle(position, 2.4, shadow);
      canvas.drawCircle(position, 1.35, orange);
    }
  }

  @override
  bool shouldRepaint(covariant _OutlinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.imageAspect != imageAspect;
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({
    required this.strokes,
    required this.activePoints,
    required this.erase,
    required this.brushSize,
    required this.imageAspect,
  });
  final List<CutoutBrushStroke> strokes;
  final List<CutoutBrushPoint>? activePoints;
  final bool erase;
  final double brushSize;
  final double imageAspect;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _draw(canvas, size, stroke.points, stroke.erase, stroke.size);
    }
    if (activePoints != null) {
      _draw(canvas, size, activePoints!, erase, brushSize);
    }
  }

  void _draw(
    Canvas canvas,
    Size size,
    List<CutoutBrushPoint> points,
    bool eraseStroke,
    double strokeSize,
  ) {
    if (points.isEmpty) return;
    final canvasAspect = size.width / size.height;
    final Rect imageRect;
    if (imageAspect > canvasAspect) {
      final height = size.width / imageAspect;
      imageRect = Rect.fromLTWH(
        0,
        (size.height - height) / 2,
        size.width,
        height,
      );
    } else {
      final width = size.height * imageAspect;
      imageRect = Rect.fromLTWH(
        (size.width - width) / 2,
        0,
        width,
        size.height,
      );
    }
    final paint = Paint()
      ..color = (eraseStroke ? Colors.red : Colors.green).withValues(
        alpha: 0.55,
      )
      ..strokeWidth = strokeSize * imageRect.width * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(
        imageRect.left + points.first.x * imageRect.width,
        imageRect.top + points.first.y * imageRect.height,
      );
    for (final point in points.skip(1)) {
      path.lineTo(
        imageRect.left + point.x * imageRect.width,
        imageRect.top + point.y * imageRect.height,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}
