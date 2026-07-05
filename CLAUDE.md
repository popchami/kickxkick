# Kick×Kick Claude Code Rules

## Start of every session

1. Read this file first.
2. Read `docs/AI_RESUME.md` next.
3. Only open large spec files when `docs/AI_RESUME.md` says they are needed.

## Source of truth

Current product specs are under:

```text
specs/KICKXKICK_*
```

Do not treat old SoleMuseum documents as current specs.

## Token saving rule

Do not summarize the whole project every time.
Use this split:

- Code = current implementation state
- `specs/KICKXKICK_*` = fixed product decisions
- `docs/AI_RESUME.md` = only the latest resume point

## Work rules

### Can proceed without confirmation

- Read files
- Search code
- Edit code
- Create small supporting files
- Run local checks
- Commit changes

### Must ask before doing

- Git push
- DB schema or migration changes
- File deletion
- Large architecture changes
- Changing fixed product specs
- Any unclear product decision

## Before ending a session

Update only `docs/AI_RESUME.md` with the smallest useful handoff.
Do not create a long report unless the user asks for it.
