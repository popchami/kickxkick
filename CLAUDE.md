# Claude Code Rules

## Session Start

1. Read this file.
2. Read `docs/AI_RESUME.md`.
3. Check the latest repository code.
4. Read only the specs required for the current task.

## Source of Truth (Priority)

1. User instructions
2. `specs/KICKXKICK_*`
3. Repository source code
4. `docs/AI_RESUME.md`

Ignore legacy SoleMuseum documents unless explicitly requested.

## Working Rules

Proceed without confirmation:
- Read/search files
- Edit code
- Create supporting files
- Run local checks
- Commit

Ask before:
- Push
- DB schema or migration changes
- File or data deletion
- Architecture changes
- Specification changes
- Unclear requirements

## Token Saving

Do not summarize the project unless requested.
Use the repository as the implementation source and `docs/AI_RESUME.md` only as the resume point.

## Session End

Update only `docs/AI_RESUME.md`.

Format:

```text
Next:
Blocked:
```

Do not write long handoff reports.
