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
  ShoeStatus _status = ShoeStatus.owned;

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
      _status = shoe.status;
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
            status: _status,
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
            status: _status,
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
            child: Text(_isEditing ? '保存' : '追加'),
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

  Future<void> _addBrandInline(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('ブランドを追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ブランド名',
            hintText: '例: Salehe Bembury',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.of(dlgCtx).pop(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(dlgCtx).pop(text);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;

    final rowId = await ref.read(brandRepositoryProvider).insertBrand(name);
    ref.invalidate(brandsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rowId > 0 ? '$name を追加しました' : '$name はすでに登録されています'),
        ),
      );
    }

    if (rowId > 0) {
      setState(() => _brandId = rowId);
    }
  }

  Widget _buildForm(List<Brand> brands) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
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
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'ブランドを追加',
                onPressed: () => _addBrandInline(context),
              ),
            ],
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
          const SizedBox(height: 16),
          Text(
            'ステータス',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ShoeStatus>(
            segments: const [
              ButtonSegment(value: ShoeStatus.owned, label: Text('所有中')),
              ButtonSegment(value: ShoeStatus.wishlist, label: Text('ほしいリスト')),
              ButtonSegment(value: ShoeStatus.sold, label: Text('売却済み')),
            ],
            selected: {_status},
            onSelectionChanged: (value) => setState(() => _status = value.first),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? '変更を保存' : 'コレクションに追加'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
