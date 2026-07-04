/// アプリ全体・Board/棚ごとに選べる背景テーマ。
/// 新しいテーマを追加する時は、ここに1件追加するだけでよい。
enum BackgroundTheme {
  orange('orange', 'assets/backgrounds/background_orange.jpg'),
  street('street', 'assets/backgrounds/background_street.jpg');

  const BackgroundTheme(this.key, this.assetPath);

  /// DB・設定に保存する文字列キー。
  final String key;

  /// 背景画像のアセットパス。
  final String assetPath;

  static const defaultTheme = BackgroundTheme.orange;

  static BackgroundTheme fromKey(String? key) => BackgroundTheme.values
      .firstWhere((theme) => theme.key == key, orElse: () => defaultTheme);
}
