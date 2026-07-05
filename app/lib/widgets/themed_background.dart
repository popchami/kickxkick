import 'package:flutter/material.dart';

import '../models/background_theme.dart';

/// 背景画像を敷いた上にchildを重ねる共通部品。
/// 指定のテーマ画像がまだ用意されていない場合は、既存のクリーム色に
/// フォールバックする（画像を後から追加すれば、コード変更なしで反映される）。
class ThemedBackground extends StatelessWidget {
  const ThemedBackground({super.key, required this.theme, required this.child});

  final BackgroundTheme theme;
  final Widget child;

  static const _fallbackColor = Color(0xFFF3E7D3);

  @override
  Widget build(BuildContext context) {
    // fit: StackFit.expand だと非Positioned要素に無制限（高さ無限大）の
    // 制約を強制してしまい、SingleChildScrollView配下（棚画面）のような
    // 高さが確定しない文脈では描画に失敗して真っ黒になる。
    // かといってデフォルトのStackFit.looseにすると、今度はchildが
    // 「全要素がPositioned」なStack（ステッカーボード等）の場合に
    // 制約がmin=0まで緩められてしまい、childが0サイズに潰れて
    // 何も表示されなくなる（棚は直るがボードのステッカーが消える）。
    // StackFit.passthroughなら親から来た制約（確定サイズでも
    // 無制限でも）をそのままchildへ伝えるため、どちらの文脈でも
    // 元々の（ThemedBackgroundを挟む前の）レイアウト結果を再現できる。
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: Image.asset(
            theme.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: _fallbackColor),
          ),
        ),
        child,
      ],
    );
  }
}
