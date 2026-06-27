import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../features/search/search.dart';
import '../models/brand.dart';
import '../models/photo.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/photo_storage_provider.dart';
import '../providers/shoe_provider.dart';
import '../widgets/app_dialogs.dart';

class ShoeFormScreen extends ConsumerStatefulWidget {
  final Shoe? shoe;

  const ShoeFormScreen({super.key, this.shoe});

  @override
  ConsumerState<ShoeFormScreen> createState() => _ShoeFormScreenState();
}

class _ShoeFormScreenState extends ConsumerState<ShoeFormScreen> {
  static final List<String> _sizeOptions = List.generate(
    21,
    (index) => (22 + index * 0.5).toStringAsFixed(1),
  );

  static const List<_ColorOption> _colorOptions = [
    _ColorOption('ブラック', Colors.black),
    _ColorOption('ホワイト', Colors.white),
    _ColorOption('グレー', Colors.grey),
    _ColorOption('レッド', Colors.red),
    _ColorOption('ブルー', Colors.blue),
    _ColorOption('グリーン', Colors.green),
    _ColorOption('イエロー', Colors.yellow),
    _ColorOption('ブラウン', Colors.brown),
    _ColorOption('ベージュ', Color(0xFFD7C4A3)),
    _ColorOption('ピンク', Colors.pink),
    _ColorOption('パープル', Colors.purple),
    _ColorOption('オレンジ', Colors.orange),
    _ColorOption('マルチカラー', null),
    _ColorOption('その他', null),
  ];

  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _displayTitleController = TextEditingController();
  final _stickerTextController = TextEditingController();
  final _priceController = TextEditingController();
  final _storeController = TextEditingController();
  final _memoController = TextEditingController();

  int? _brandId;
  String _brandText = '';
  String _status = Shoe.statusNew;
  String? _selectedSize;
  String? _selectedColor;
  DateTime? _purchaseDate;
  XFile? _pendingMainPhoto;
  bool _saving = false;
  String? _lastAutoDisplayTitle;
  String? _lastAutoStickerText;

  bool get _isEditing => widget.shoe != null;

  @override
  void initState() {
    super.initState();
    final shoe = widget.shoe;
    if (shoe != null) {
      _brandId = shoe.brandId;
      _modelController.text = shoe.modelName;
      _displayTitleController.text = shoe.displayTitle ?? '';
      _stickerTextController.text = shoe.stickerText ?? '';
      _status = Shoe.normalizeStatus(shoe.status);
      _selectedSize = shoe.size;
      _selectedColor = shoe.color;
      _priceController.text = shoe.purchasePrice?.toString() ?? '';
      _storeController.text = shoe.purchaseStore ?? '';
      _memoController.text = shoe.memo ?? '';
      _purchaseDate = shoe.purchaseDate;
    }
    _modelController.addListener(_syncModelNameFields);
  }

  @override
  void dispose() {
    _modelController.removeListener(_syncModelNameFields);
    _modelController.dispose();
    _displayTitleController.dispose();
    _stickerTextController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickMainPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _pendingMainPhoto = picked);
    }
  }

  Future<void> _save() async {
    final modelName = _modelController.text.trim();
    if (!_formKey.currentState!.validate() ||
        (_brandId == null && _brandText.trim().isEmpty) ||
        modelName.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    final shoeRepository = ref.read(shoeRepositoryProvider);
    final brandRepository = ref.read(brandRepositoryProvider);
    final priceText = _priceController.text.trim();
    final price = priceText.isEmpty ? null : int.tryParse(priceText);

    try {
      final resolvedBrandId = _brandId ??
          (await brandRepository.findOrCreateByName(_brandText.trim())).id!;

      late final int shoeId;
      if (_isEditing) {
        final current = widget.shoe!;
        shoeId = current.id!;
        await shoeRepository.updateShoe(
          Shoe(
            id: current.id,
            brandId: resolvedBrandId,
            modelName: modelName,
            displayTitle: _emptyToNull(_displayTitleController.text),
            stickerText: _emptyToNull(_stickerTextController.text),
            status: _status,
            size: _selectedSize,
            color: _selectedColor,
            purchaseDate: _purchaseDate,
            purchasePrice: price,
            purchaseStore: _emptyToNull(_storeController.text),
            memo: _emptyToNull(_memoController.text),
            isFavorite: current.isFavorite,
            topOrder: current.topOrder,
            createdAt: current.createdAt,
            updatedAt: current.updatedAt,
          ),
        );
      } else {
        shoeId = await shoeRepository.insertShoe(
          Shoe.create(
            brandId: resolvedBrandId,
            modelName: modelName,
            displayTitle: _emptyToNull(_displayTitleController.text),
            stickerText: _emptyToNull(_stickerTextController.text),
            status: _status,
            size: _selectedSize,
            color: _selectedColor,
            purchaseDate: _purchaseDate,
            purchasePrice: price,
            purchaseStore: _emptyToNull(_storeController.text),
            memo: _emptyToNull(_memoController.text),
            isFavorite: false,
          ),
        );
      }

      if (_pendingMainPhoto != null) {
        await _saveMainPhoto(shoeId, _pendingMainPhoto!);
      }

      ref.invalidate(brandsProvider);
      ref.invalidate(shoesProvider);
      ref.invalidate(shoeByIdProvider(shoeId));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      debugPrint('Shoe save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _saving = false);
        await showAppMessage(context, title: '保存できませんでした');
      }
    }
  }

  Future<void> _saveMainPhoto(int shoeId, XFile pickedFile) async {
    final storage = ref.read(photoStorageServiceProvider);
    final filePath = await storage.savePhoto(
      sourceFile: File(pickedFile.path),
      shoeId: shoeId,
      photoType: PhotoType.main,
    );
    final repository = ref.read(photoRepositoryProvider);
    final previousPhotos = await repository.replaceMainPhoto(
      Photo.create(
        shoeId: shoeId,
        photoType: PhotoType.main,
        filePath: filePath,
      ),
    );
    for (final previousPhoto in previousPhotos) {
      try {
        await storage.deletePhotoFile(previousPhoto.filePath);
      } catch (_) {
        // Database replacement already succeeded; cleanup is best effort.
      }
    }
    ref.invalidate(photosByShoeIdProvider(shoeId));
    ref.invalidate(mainPhotoProvider(shoeId));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(1980),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null) {
      setState(() => _purchaseDate = selected);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _syncModelNameFields() {
    final modelName = _modelController.text.trim();
    if (modelName.isEmpty) {
      return;
    }

    _syncTextController(
      controller: _displayTitleController,
      value: _limitText(modelName, 10),
      lastAutoValue: _lastAutoDisplayTitle,
      setLastAutoValue: (value) => _lastAutoDisplayTitle = value,
    );
    _syncTextController(
      controller: _stickerTextController,
      value: _limitText(modelName, 15),
      lastAutoValue: _lastAutoStickerText,
      setLastAutoValue: (value) => _lastAutoStickerText = value,
    );
  }

  void _syncTextController({
    required TextEditingController controller,
    required String value,
    required String? lastAutoValue,
    required ValueChanged<String> setLastAutoValue,
  }) {
    final current = controller.text.trim();
    if (current.isNotEmpty && current != lastAutoValue) {
      return;
    }

    setLastAutoValue(value);
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _limitText(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return trimmed.characters.take(maxLength).toString();
  }

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(brandsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'スニーカー編集' : 'スニーカーを登録'),
      ),
      body: brandsAsync.when(
        data: (brands) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('メイン写真', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _PhotoPickerCard(
                pickedFile: _pendingMainPhoto,
                onTap: _pickMainPhoto,
                onRemove: () => setState(() => _pendingMainPhoto = null),
              ),
              const SizedBox(height: 28),
              Text('基本情報', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildBasicInfo(brands),
              const SizedBox(height: 28),
              Text('サイズ・カラー', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildAppearance(),
              const SizedBox(height: 28),
              Text('購入情報・メモ', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildDetails(),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(_saving ? '保存中…' : _isEditing ? '変更を保存' : '登録する'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('ブランドを読み込めませんでした')),
      ),
    );
  }

  Widget _buildBasicInfo(List<Brand> brands) {
    final initialBrandName = _brandNameForId(brands, _brandId);
    if (_brandText.isEmpty && initialBrandName != null) {
      _brandText = initialBrandName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SneakerMasterPicker(
          initialBrandName: initialBrandName,
          initialModelName: _modelController.text,
          onChanged: (selection) {
            final matchedBrand = _findLocalBrand(brands, selection.brandName);
            setState(() {
              _brandText = selection.brandName;
              _brandId = matchedBrand?.id;
              _modelController.text = selection.modelName;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey(_brandId),
          initialValue: _brandId,
          decoration: const InputDecoration(
            labelText: '保存するブランド',
            helperText: '自由入力の場合は未選択のままで保存できます',
          ),
          items: brands
              .map(
                (brand) => DropdownMenuItem<int>(
                  value: brand.id,
                  child: Text(brand.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            final brandName = _brandNameForId(brands, value) ?? _brandText;
            setState(() {
              _brandId = value;
              _brandText = brandName;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: '保存するモデル名',
            helperText: '候補がない場合は自由入力できます',
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'モデル名を入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayTitleController,
          decoration: const InputDecoration(
            labelText: 'Display Title',
            helperText: '棚や一覧で使う愛称。最大10文字',
          ),
          maxLength: 10,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _stickerTextController,
          decoration: const InputDecoration(
            labelText: 'ステッカーテキスト',
            helperText: 'ステッカー生成で使う短い文字。最大15文字',
          ),
          maxLength: 15,
        ),
      ],
    );
  }

  Brand? _findLocalBrand(List<Brand> brands, String brandName) {
    final normalized = brandName.trim().toLowerCase();
    for (final brand in brands) {
      if (brand.name.trim().toLowerCase() == normalized) {
        return brand;
      }
    }
    return null;
  }

  String? _brandNameForId(List<Brand> brands, int? brandId) {
    if (brandId == null) return null;
    for (final brand in brands) {
      if (brand.id == brandId) return brand.name;
    }
    return null;
  }

  Widget _buildAppearance() {
    final sizes = [..._sizeOptions];
    if (_selectedSize != null && !sizes.contains(_selectedSize)) {
      sizes.add(_selectedSize!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedSize,
          decoration: const InputDecoration(
            labelText: 'サイズ',
            suffixText: 'cm',
          ),
          items: sizes
              .map(
                (size) =>
                    DropdownMenuItem(value: size, child: Text('$size cm')),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedSize = value),
        ),
        const SizedBox(height: 24),
        Text('カラー', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorOptions.map((option) {
            return ChoiceChip(
              avatar: option.color == null
                  ? const Icon(Icons.palette_outlined, size: 18)
                  : CircleAvatar(
                      backgroundColor: option.color,
                      child: option.color == Colors.white
                          ? const Icon(Icons.circle_outlined, size: 16)
                          : null,
                    ),
              label: Text(option.label),
              selected: _selectedColor == option.label,
              onSelected: (_) => setState(() => _selectedColor = option.label),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: '状態'),
          items: const [
            DropdownMenuItem(value: Shoe.statusNew, child: Text('新品')),
            DropdownMenuItem(value: Shoe.statusWorn, child: Text('着用済み')),
            DropdownMenuItem(value: Shoe.statusParted, child: Text('手放した')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _status = value);
            }
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('購入日'),
          subtitle: Text(
            _purchaseDate == null
                ? '未設定'
                : '${_purchaseDate!.year}/${_purchaseDate!.month}/${_purchaseDate!.day}',
          ),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(labelText: '購入価格', suffixText: '円'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storeController,
          decoration: const InputDecoration(labelText: '購入店'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _memoController,
          decoration: const InputDecoration(labelText: 'メモ'),
          maxLines: 4,
          maxLength: 300,
        ),
      ],
    );
  }
}

class _PhotoPickerCard extends StatelessWidget {
  final XFile? pickedFile;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoPickerCard({
    required this.pickedFile,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final file = pickedFile;
    if (file == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 48),
              SizedBox(height: 12),
              Text('メイン写真を選択'),
              SizedBox(height: 4),
              Text('スキップできます'),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(file.path),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton.filled(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('選び直す'),
          ),
        ),
      ],
    );
  }
}

class _ColorOption {
  final String label;
  final Color? color;

  const _ColorOption(this.label, this.color);
}
