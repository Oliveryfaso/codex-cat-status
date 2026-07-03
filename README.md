# Codex Cat Status

Small macOS menu bar companion for Codex Desktop.

It does not modify `/Applications/Codex.app`. Instead, it reads local Codex state under `~/.codex` and shows a tiny animated bitmap sprite in the menu bar:

- Running sprite: any recent Codex conversation whose latest turn has started but has not completed, an unfinished Codex tool/command call in that active turn, or an active local job.
- Alert sprite: an unfinished command whose arguments explicitly request `sandbox_permissions=require_escalated`, or a local job that explicitly needs review/approval.
- Resting sprite: idle.

Status is inferred from local Codex files, because Codex Desktop does not expose a public menu-bar status API. The menu item shows the signal counts used for the current state:

- `conversation`: recent Codex sessions whose latest turn has started and has not yet written `task_complete`.
- `pending`: unfinished tool or command calls in active Codex turns.
- `jobs`: active local agent or automation jobs.
- `review`: unfinished approval-required commands or explicit review/approval jobs.

The alert state intentionally avoids broad text matching. It only appears for an unfinished approval-required command, while normal thinking/writing stays in the running state.

Build:

```sh
sh build.sh
```

Run:

```sh
open CodexCatStatus.app
```

Generate state previews:

```sh
python3 generate_previews.py
```

Quit from the menu bar item: `Quit Codex Cat`.
