# Claude Code Workflow

## New Session (Termux / Desktop)

Send this once at the beginning of every new Claude Code session:

```text
CLAUDE.md と docs/AI_RESUME.md を読んで、前回の続きから再開してください。

最新のコードを確認し、必要な仕様書だけ読んで作業してください。
```

After this, do not repeat the message unless a new Claude Code session starts.

---

## During Work

Send only normal requests or design decisions from ChatGPT/Claude.

Example:

```text
ChatGPTと相談した結果、以下の仕様に変更します。

(相談結果)
```

---

## End of Work (No Push)

```text
作業を終了します。

docs/AI_RESUME.md を更新してください。

記載するのは以下だけです。

Next:
Blocked:

その後、commitしてください。
pushはしないでください。
```

---

## End of Work (Push)

```text
作業を終了します。

commitして、pushしてください。

その後、docs/AI_RESUME.md を更新してください。

記載するのは以下だけです。

Next:
Blocked:
```

---

## Shared Sources

- Source code = implementation
- Git history = change history
- docs/AI_RESUME.md = next task and blockers
- specs/ = product specifications
- CLAUDE.md = working rules
