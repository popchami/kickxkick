import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search.dart';

class BrandSearchField extends ConsumerStatefulWidget {
  const BrandSearchField({
    super.key,
    required this.onSelected,
    this.onTextChanged,
    this.initialText,
  });

  final ValueChanged<BrandMaster> onSelected;
  final ValueChanged<String>? onTextChanged;
  final String? initialText;

  @override
  ConsumerState<BrandSearchField> createState() => _BrandSearchFieldState();
}

class _BrandSearchFieldState extends ConsumerState<BrandSearchField> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _query = widget.initialText ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(searchServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'ブランド',
            hintText: 'Nike / adidas / New Balance など',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() => _query = value);
            widget.onTextChanged?.call(value);
          },
        ),
        const SizedBox(height: 8),
        serviceAsync.when(
          data: (service) {
            final suggestions = service.suggestBrands(_query);
            if (suggestions.isEmpty) {
              return const _SearchHint(text: '候補がありません。自由入力できます。');
            }

            return _SuggestionList(
              children: suggestions.map((suggestion) {
                return ListTile(
                  dense: true,
                  title: Text(suggestion.brand.brandName),
                  onTap: () {
                    _controller.text = suggestion.brand.brandName;
                    setState(() => _query = suggestion.brand.brandName);
                    widget.onTextChanged?.call(suggestion.brand.brandName);
                    widget.onSelected(suggestion.brand);
                    FocusScope.of(context).nextFocus();
                  },
                );
              }).toList(),
            );
          },
          loading: () => const _SearchHint(text: 'ブランド候補を読み込み中...'),
          error: (error, stackTrace) => _SearchHint(text: 'ブランド候補を読み込めませんでした: $error'),
        ),
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: children,
        ),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
