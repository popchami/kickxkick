# Claude Code Workflow

このファイルは人（開発者）が読む運用マニュアルです。

---

# 役割

- CLAUDE.md：Claude Code用ルール
- docs/AI_RESUME.md：現在の作業状態
- specs/：確定仕様
- GitHubコード：現在の実装

---

# 新しいClaude Codeセッション開始（Termux / Desktop共通）

最初に一度だけ送る。

```text
CLAUDE.md と docs/AI_RESUME.md を読んで、前回の続きから再開してください。

最新のコードを確認し、必要な仕様書だけ読んで作業してください。
```

以降、このセッションでは繰り返さない。

---

# 作業中

通常どおり会話する。

仕様変更が決まった場合だけ送る。

```text
ChatGPTと相談した結果、以下の仕様に変更します。

（相談結果）
```

---

# 作業終了（pushしない）

```text
作業を終了します。

docs/AI_RESUME.md を更新してください。

記載するのは

Next:
Blocked:

のみです。

その後 commit してください。
pushはしないでください。
```

---

# 作業終了（pushする）

```text
作業を終了します。

commitして、pushしてください。

その後 docs/AI_RESUME.md を更新してください。

記載するのは

Next:
Blocked:

のみです。
```

---

# 次回

新しいClaude Codeセッションを開始したら、再び「新しいClaude Codeセッション開始」のコピペから始める。
