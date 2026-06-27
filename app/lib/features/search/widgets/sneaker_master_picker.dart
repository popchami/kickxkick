import 'package:flutter/material.dart';

import '../search.dart';

class SneakerMasterSelection {
  const SneakerMasterSelection({
    required this.brandId,
    required this.brandName,
    required this.modelId,
    required this.modelName,
    required this.isMasterModel,
  });

  final String? brandId;
  final String brandName;
  final String? modelId;
  final String modelName;
  final bool isMasterModel;
}

class SneakerMasterPicker extends StatefulWidget {
  const SneakerMasterPicker({
    super.key,
    required this.onChanged,
    this.initialBrandName,
    this.initialModelName,
  });

  final ValueChanged<SneakerMasterSelection> onChanged;
  final String? initialBrandName;
  final String? initialModelName;

  @override
  State<SneakerMasterPicker> createState() => _SneakerMasterPickerState();
}

class _SneakerMasterPickerState extends State<SneakerMasterPicker> {
  BrandMaster? _selectedBrand;
  ModelSuggestion? _selectedModel;
  late String _brandText;
  late String _modelText;

  @override
  void initState() {
    super.initState();
    _brandText = widget.initialBrandName ?? '';
    _modelText = widget.initialModelName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSearchField(
          initialText: widget.initialBrandName,
          onTextChanged: (value) {
            setState(() {
              _brandText = value;
              _selectedBrand = null;
              _selectedModel = null;
              _modelText = '';
            });
            _emit();
          },
          onSelected: (brand) {
            setState(() {
              _selectedBrand = brand;
              _brandText = brand.brandName;
              _selectedModel = null;
              _modelText = '';
            });
            _emit();
          },
        ),
        const SizedBox(height: 16),
        ModelSearchField(
          key: ValueKey(_selectedBrand?.brandId),
          brandId: _selectedBrand?.brandId,
          brandName: _brandText,
          initialText: widget.initialModelName,
          onTextChanged: (value) {
            setState(() {
              _modelText = value;
              _selectedModel = null;
            });
            _emit();
          },
          onSelected: (suggestion) {
            setState(() {
              _selectedModel = suggestion;
              _modelText = suggestion.canonicalName;
            });
            _emit();
          },
        ),
      ],
    );
  }

  void _emit() {
    widget.onChanged(
      SneakerMasterSelection(
        brandId: _selectedBrand?.brandId,
        brandName: _brandText.trim(),
        modelId: _selectedModel?.model.id,
        modelName: _modelText.trim(),
        isMasterModel: _selectedModel != null,
      ),
    );
  }
}
