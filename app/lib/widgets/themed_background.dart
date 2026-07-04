import 'package:flutter/material.dart';

import '../models/background_theme.dart';

/// 背景画像を敷いた上にchildを重ねる共通部品。
/// 指定のテーマ画像がまだ用意されていない場合は、既存のクリーム色に
/// フォールバックする（画像を後から追加すれば、コード変更なしで反映される）。
class ThemedBackground extends StatelessWidget {
  const ThemedBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  final BackgroundTheme theme;
  final Widget child;

  static const _fallbackColor = Color(0xFFF3E7D3);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          theme.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: _fallbackColor),
        ),
        child,
      ],
    );
  }
}
