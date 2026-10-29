# projects

- **What exists:** ranks the projects under `project_dirs` (or `--dir`) by a note's distinctive terms, reading each project's `README.md`, `plan/pending.md` and `plan/workplan.md`, and marks a project that already cites the source.
- **How a user reaches it:** `/capture-nt` Step 10; by hand, `scholia projects <slug | text>`.
- **Drive it:** `verify/verify verify projects` (uses `demo/seed/projects`).
- **What usually lies:** with no config it prints a hint and exits 0. A string `project_dirs` is rejected (M4) rather than read letter by letter.
