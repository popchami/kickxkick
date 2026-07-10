Next:
- streetテーマのアイコン14個は、ComfyUIでのSVG生成がまだ未着手
  （nav_homeの元絵(PNG、512×512)のみ作成済み）。SVGが揃ったら、
  ThemedIconウィジェット(widgets/themed_icon.dart)へ
  main.dart・各画面のアイコンを実際に置き換える作業も残っている
- 今回までにまとめて実装した以下の変更は、いずれも実機での
  動作確認がまだ（PC使用可能時に一括確認）:
  - ステッカーのドラッグ/回転パフォーマンス改善(_StickerBoardItemView化)
  - 上下バーのorange/streetテーマ連動配色
  - ステッカーボード・コレクション棚の共有画像を高画質書き出し方式に変更
  - LINEスタンプ用ステッカー単体書き出し(1024×1024・透過PNG)
  - flutter_svg追加・ThemedIcon土台(SVGはまだ0個)
- (自走モードで完了) 未使用コードの掃除4件をcommit・push済み:
  _shareKeys削除(16755d2)、未使用AppFabウィジェット削除(ace1840)、
  不要なcross_file依存の削除(98916ed)、未使用MuseumSummaryウィジェット
  削除(ba8fcee)。cross_file削除のみ、次回PC使用時にflutter pub get/
  buildで問題なく動くか要確認
- 上記以外の掃除候補(print()直書き、空catch、重複import、コメント
  アウトされた不要コード)は調査済みで、いずれも問題なし(対応不要)
- ML Kit（AI背景除去）が実際に成功しているか、ログを見て確認する
  （ずっと保留中）

Blocked:
- なし（PCが一時的に使えないため、実機確認系のみ保留中）
