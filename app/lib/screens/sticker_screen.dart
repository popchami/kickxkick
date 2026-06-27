import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/shoe.dart';
import '../models/sticker_asset.dart';
import '../providers/photo_provider.dart';
import '../providers/shoe_provider.dart';
import '../providers/sticker_provider.dart';
import '../services/background_removal_service.dart';
import '../widgets/empty_state.dart';

class StickerScreen extends ConsumerStatefulWidget {
  const StickerScreen({super.key});

  @override
  ConsumerState<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends ConsumerState<StickerScreen> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final stickersAsync = ref.watch(stickersProvider);
    final shoes = ref.watch(shoesProvider).value ?? const <Shoe>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker'),
        actions: [
          IconButton(
            onPressed: shoes.isEmpty ? null : () => _createSticker(shoes),
            icon: const Icon(Icons.add),
            tooltip: 'ステッカーを作る',
          ),
        ],
      ),
      body: stickersAsync.when(
        data: (stickers) {
          if (stickers.isEmpty) {
            return EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: 'まだステッカーがありません',
              description: '写真を登録したスニーカーからステッカーを作れます。',
              actionLabel: 'ステッカーを作る',
              onAction: shoes.isEmpty ? null : () => _createSticker(shoes),
            );
          }
          return FutureBuilder<_BoardData>(
            key: ValueKey(_revision),
            future: _loadBoard(stickers),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final data = snapshot.data!;
              return _StickerBoard(
                stickers: stickers,
                items: data.items,
                onChanged: (item) => ref.read(stickerRepositoryProvider).updateBoardItem(item),
                onDuplicate: (item) => ref.read(stickerRepositoryProvider).duplicateBoardItem(item),
                onDelete: (item) => ref.read(stickerRepositoryProvider).deleteBoardItem(item.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('ステッカーを読み込めませんでした')),
      ),
    );
  }

  Future<_BoardData> _loadBoard(List<StickerAsset> stickers) async {
    final repository = ref.read(stickerRepositoryProvider);
    final boardId = await repository.ensureDefaultBoard();
    for (final sticker in stickers) {
      await repository.addToBoard(boardId, sticker.id);
    }
    return _BoardData(boardId, await repository.getBoardItems(boardId));
  }

  Future<void> _createSticker(List<Shoe> shoes) async {
    final shoe = await showDialog<Shoe>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スニーカーを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shoes.length,
            itemBuilder: (context, index) {
              final shoe = shoes[index];
              return ListTile(
                title: Text(shoe.displayTitle?.isNotEmpty == true ? shoe.displayTitle! : shoe.modelName),
                onTap: () => Navigator.pop(context, shoe),
              );
            },
          ),
        ),
      ),
    );
    if (shoe == null || !mounted) return;
    final photo = await ref.read(photoRepositoryProvider).getMainPhoto(shoe.id!);
    if (!mounted) return;
    if (photo == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('メイン写真が必要です'),
          content: const Text('Detail画面で写真を追加してから作成してください。'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final output = await BackgroundRemovalService().removeEdgeBackground(photo.filePath, shoe.id!);
      await ref.read(stickerRepositoryProvider).saveSticker(shoeId: shoe.id!, sourcePath: photo.filePath, stickerPath: output);
      ref.invalidate(stickersProvider);
      setState(() => _revision++);
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ステッカーを作成できませんでした'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
          ),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

class _BoardData {
  const _BoardData(this.boardId, this.items);
  final int boardId;
  final List<StickerBoardItem> items;
}

class _StickerBoard extends StatefulWidget {
  const _StickerBoard({required this.stickers, required this.items, required this.onChanged, required this.onDuplicate, required this.onDelete});
  final List<StickerAsset> stickers;
  final List<StickerBoardItem> items;
  final ValueChanged<StickerBoardItem> onChanged;
  final Future<StickerBoardItem> Function(StickerBoardItem) onDuplicate;
  final Future<void> Function(StickerBoardItem) onDelete;

  @override
  State<_StickerBoard> createState() => _StickerBoardState();
}

class _StickerBoardState extends State<_StickerBoard> {
  late final List<StickerBoardItem> _items = [...widget.items];
  final List<List<StickerBoardItem>> _history = [];
  final List<List<StickerBoardItem>> _future = [];
  int? _selectedId;
  double _startScale = 1;
  double _startRotation = 0;
  final GlobalKey _boardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final assets = {for (final value in widget.stickers) value.id: value};
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Center(
            child: Padding(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _boardKey,
          child: AspectRatio(
          aspectRatio: 4 / 5,
          child: LayoutBuilder(
            builder: (context, constraints) => DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF3E7D3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: _items.map((item) {
                  final asset = assets[item.stickerId];
                  if (asset == null) return const SizedBox.shrink();
                  return Positioned(
                    left: item.x * constraints.maxWidth,
                    top: item.y * constraints.maxHeight,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedId = item.id),
                      onScaleStart: (_) {
                        _pushHistory();
                        _selectedId = item.id;
                        _startScale = item.scale;
                        _startRotation = item.rotation;
                      },
                      onScaleUpdate: (details) {
                        final index = _items.indexWhere((value) => value.id == item.id);
                        setState(() {
                          _items[index] = StickerBoardItem(
                            id: item.id, boardId: item.boardId, stickerId: item.stickerId,
                            x: (item.x + details.focalPointDelta.dx / constraints.maxWidth).clamp(0, .78),
                            y: (item.y + details.focalPointDelta.dy / constraints.maxHeight).clamp(0, .82),
                            scale: (_startScale * details.scale).clamp(.5, 2.5),
                            rotation: _startRotation + details.rotation,
                            zIndex: item.zIndex,
                          );
                        });
                      },
                      onScaleEnd: (_) => widget.onChanged(_items.firstWhere((value) => value.id == item.id)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: item.id == _selectedId ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                        ),
                        child: Transform.rotate(
                          angle: item.rotation,
                          child: Transform.scale(
                            scale: item.scale,
                            child: Image.file(File(asset.stickerPath), width: 110, height: 110, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final selected = _selectedId == null
        ? null
        : _items.where((item) => item.id == _selectedId).firstOrNull;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: _history.isEmpty ? null : _undo, icon: const Icon(Icons.undo), tooltip: '元に戻す'),
        IconButton(onPressed: _future.isEmpty ? null : _redo, icon: const Icon(Icons.redo), tooltip: 'やり直す'),
        IconButton(
          onPressed: selected == null ? null : () async {
            final value = await widget.onDuplicate(selected);
            setState(() { _items.add(value); _selectedId = value.id; });
          },
          icon: const Icon(Icons.copy_outlined),
          tooltip: '複製',
        ),
        IconButton(
          onPressed: selected == null ? null : () async {
            await widget.onDelete(selected);
            setState(() { _items.removeWhere((item) => item.id == selected.id); _selectedId = null; });
          },
          icon: const Icon(Icons.delete_outline),
          tooltip: 'ボードから削除',
        ),
        IconButton(
          onPressed: _exportBoard,
          icon: const Icon(Icons.ios_share_outlined),
          tooltip: 'PNG出力',
        ),
      ],
    );
  }

  void _pushHistory() {
    _history.add([..._items]);
    if (_history.length > 30) _history.removeAt(0);
    _future.clear();
  }

  void _undo() {
    _future.add([..._items]);
    final previous = _history.removeLast();
    setState(() { _items..clear()..addAll(previous); });
    for (final item in _items) {
      widget.onChanged(item);
    }
  }

  void _redo() {
    _history.add([..._items]);
    final next = _future.removeLast();
    setState(() { _items..clear()..addAll(next); });
    for (final item in _items) {
      widget.onChanged(item);
    }
  }

  Future<void> _exportBoard() async {
    final boundary = _boardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, 'kickxkick_board_${DateTime.now().millisecondsSinceEpoch}.png'));
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'KickxKick Sticker Board'));
  }
}
