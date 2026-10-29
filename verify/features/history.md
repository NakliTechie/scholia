# history

- **What exists:** dated search of one ntkit `plan/` folder, `_archive/` included, with no vault; `--since --until --chrono --limit`.
- **How a user reaches it:** `scholia history <terms> --plan <repo>` or from a repo root.
- **Drive it:** `verify/verify verify history` (copies `demo/seed/plan-history` to `repo/plan`).
- **What usually lies:** a broken `scholia.toml` in the working directory's vault does not stop `history` (M4). Unreadable plan files are skipped silently.
