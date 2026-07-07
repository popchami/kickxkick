前回やったこと:
- ステッカーのドラッグ/回転パフォーマンス改善（_StickerBoardItemView化、
  ドラッグ中に板全体ではなく該当ステッカーだけ再描画されるように変更）
- 上下バー（AppBar/NavigationBar）をorange/streetテーマ連動配色に変更
- ステッカーボード・コレクション棚の共有画像を、画面スクリーンショット
  方式から高画質書き出し方式に変更
- LINEスタンプ用にステッカー単体を1024×1024・透過PNGで書き出す機能を追加
- flutter_svg依存関係の追加と、ThemedIconウィジェットの土台作成
  （streetテーマ用SVGはまだ0個、今後追加すればコード変更なしで反映）

Next:
- streetテーマのアイコン14個は、ComfyUIでのSVG生成がまだ未着手
  （nav_homeの元絵(PNG、512×512)のみ作成済み）。SVGが揃ったら、
  今回追加したThemedIconウィジェット(widgets/themed_icon.dart)へ
  main.dart・各画面のアイコンを実際に置き換える作業も残っている
- 今回のセッションでまとめて実装した以下の変更は、いずれも実機での
  動作確認がまだ（PC使用可能時に一括確認）:
  - ステッカーのドラッグ/回転パフォーマンス改善(_StickerBoardItemView化)
  - 上下バーのorange/streetテーマ連動配色
  - ステッカーボード・コレクション棚の共有画像を高画質書き出し方式に変更
  - LINEスタンプ用ステッカー単体書き出し(1024×1024・透過PNG)
  - flutter_svg追加・ThemedIcon土台(SVGはまだ0個)
- collection_screen.dartの_shareKeys/_shareKeyFor(旧・画面スクリーン
  ショット方式の名残)が、高画質書き出し方式への切替後も未使用のまま
  残っている。実機確認後、不要なら削除を検討
- ML Kit（AI背景除去）が実際に成功しているか、ログを見て確認する
  （ずっと保留中）

Blocked:
- なし（PCが一時的に使えないため、実機確認系のみ保留中）
