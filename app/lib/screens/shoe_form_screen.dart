import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/shoe.dart';
import '../providers/brand_provider.dart';
import '../providers/shoe_provider.dart';

class ShoeFormScreen extends ConsumerStatefulWidget {
  final Shoe? shoe;

  const ShoeFormScreen({super.key, this.shoe});

  @override
  ConsumerState<ShoeFormScreen> createState() => _ShoeFormScreenState();
}

class _ShoeFormScreenState extends ConsumerState<ShoeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  final _storeController = TextEditingController();
  final _memoController = TextEditingController();

  int? _brandId;
  DateTime? _purchaseDate;
  bool _isFavorite = false;

  bool get _isEditing => widget.shoe != null;

  @override
  void initState() {
    super.initState();
    final shoe = widget.shoe;
    if (shoe != null) {
      _brandId = shoe.brandId;
      _modelController.text = shoe.modelName;
      _sizeController.text = shoe.size ?? '';
      _colorController.text = shoe.color ?? '';
      _priceController.text = shoe.purchasePrice?.toString() ?? '';
      _storeController.text = shoe.purchaseStore ?? '';
      _memoController.text = shoe.memo ?? '';
      _purchaseDate = shoe.purchaseDate;
      _isFavorite = shoe.isFavorite;
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _brandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブランドとモデル名を入力してください')),
      );
      return;
    }

    final repository = ref.read(shoeRepositoryProvider);
    final priceText = _priceController.text.trim();
    final price = priceText.isEmpty ? null : int.tryParse(priceText);

    try {
      if (_isEditing) {
        final current = widget.shoe!;
        await repository.updateShoe(
          current.copyWith(
            brandId: _brandId,
            modelName: _modelController.text.trim(),
            size: _emptyToNull(_sizeController.text),
            color: _emptyToNull(_colorController.text),
            purchaseDate: _purchaseDate,
            purchasePrice: price,
            purchaseStore: _emptyToNull(_storeController.text),
            memo: _emptyToNull(_memoController.text),
            isFavorite: _isFavorite,
          ),
        );
      } else {
        await repository.insertShoe(
          Shoe.create(
            brandId: _brandId!,
            modelName: _modelController.text.trim(),
            size: _emptyToNull(_sizeController.text),
            color: _emptyToNull(_colorController.text),
            purchaseDate: _purchaseDate,
            purchasePrice: price,
            purchaseStore: _emptyToNull(_storeController.text),
            memo: _emptyToNull(_memoController.text),
            isFavorite: _isFavorite,
          ),
        );
      }

      ref.invalidate(shoesProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存に失敗しました')),
        );
      }
    }
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
      setState(() {
        _purchaseDate = selected;
      });
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'スニーカー編集' : 'スニーカー登録'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: brandsAsync.when(
        data: (brands) => _buildForm(brands),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('ブランドの読み込みに失敗しました')),
      ),
    );
  }

  Widget _buildForm(List<Brand> brands) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: _brandId,
            decoration: const InputDecoration(labelText: 'ブランド'),
            items: brands
                .map(
                  (brand) => DropdownMenuItem<int>(
                    value: brand.id,
                    child: Text(brand.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _brandId = value;
              });
            },
            validator: (value) => value == null ? 'ブランドを選択してください' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(labelText: 'モデル名'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'モデル名を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sizeController,
            decoration: const InputDecoration(labelText: 'サイズ'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _colorController,
            decoration: const InputDecoration(labelText: 'カラー'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('購入日'),
            subtitle: Text(_purchaseDate == null
                ? '未設定'
                : '${_purchaseDate!.year}/${_purchaseDate!.month}/${_purchaseDate!.day}'),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: '購入価格'),
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
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('お気に入り'),
            value: _isFavorite,
            onChanged: (value) {
              setState(() {
                _isFavorite = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
