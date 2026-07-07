import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/background_theme.dart';
import '../providers/settings_provider.dart';

/// バンドル済みアセット一覧(AssetManifest)を1回だけ読み込み、
/// 以降はキャッシュを使い回す。ThemedIconが「対応するSVGが実際に
/// 存在するか」を判定するために使う。
final _assetManifestProvider = FutureProvider<AssetManifest>((ref) {
  return AssetManifest.loadFromAssetBundle(rootBundle);
});

/// street テーマが選択されていて、かつ対応するSVGファイルが
/// assets/icons/street/ に実際に存在する場合はそのSVGを表示し、
/// それ以外(orangeテーマ、またはSVGファイルがまだ存在しない場合)は
/// 従来通りの標準アイコン(IconData)を表示する共通ウィジェット。
///
/// 現時点ではSVGファイルは1つも用意されていないため、常に標準アイコンに
/// フォールバックする。将来 assets/icons/street/ にSVGファイルを追加
/// すれば、コード変更なしで自動的にそちらが使われるようになる
/// (pubspec.yamlのassetsにフォルダ指定で登録済みのため)。
class ThemedIcon extends ConsumerWidget {
  const ThemedIcon({
    super.key,
    required this.name,
    required this.fallback,
    this.size,
    this.color,
  });

  /// street テーマ用SVGのファイル名(拡張子なし)。
  /// 例: 'nav_home' → assets/icons/street/nav_home.svg
  final String name;

  /// SVGが無い場合に表示する、これまで通りのMaterialアイコン。
  final IconData fallback;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundTheme =
        ref.watch(appBackgroundThemeProvider).value ??
        BackgroundTheme.defaultTheme;
    if (backgroundTheme != BackgroundTheme.street) {
      return Icon(fallback, size: size, color: color);
    }

    final manifest = ref.watch(_assetManifestProvider).value;
    final svgPath = 'assets/icons/street/$name.svg';
    if (manifest == null || !manifest.listAssets().contains(svgPath)) {
      return Icon(fallback, size: size, color: color);
    }

    return SvgPicture.asset(
      svgPath,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
      // AssetManifestでの存在確認は「ファイルがバンドルされているか」しか
      // 保証しないため、中身が壊れたSVGだった場合の保険として二重に
      // フォールバックする。
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallback, size: size, color: color),
    );
  }
}
