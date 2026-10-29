# semantic

- **What exists:** `scholia semantic <text>` and `--semantic` on `related` and `orient`, through fastembed and the `all-MiniLM-L6-v2` encoder (~90 MB, downloaded once to `~/.cache/scholia/models`).
- **How a user reaches it:** `uv run --with-requirements requirements-semantic.txt bin/scholia semantic ...`.
- **Drive it:** `verify/verify verify semantic` drives only the missing-fastembed path (exit 3 with the install hint; `--semantic` falls back with a note).
- **Unreachable:** the embedding path itself. Prerequisite: fastembed installed and the model downloaded, which the harness forbids (no downloads, shared GPU machine). Route attempted: `scholia semantic licence` with fastembed blocked.
