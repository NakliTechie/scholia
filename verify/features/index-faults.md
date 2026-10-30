# index-faults

- **What exists:** `.scholia.db` is a rebuildable cache. A garbage or empty index is rebuilt silently. An unwritable index (read-only vault, a directory in its place) gets one stderr line naming the path, and a read command that must rebuild uses an in-memory index for that run, while a current index already on disk is still read (M7); `scholia build` there exits 2 naming the path (M5). A broken or wrong-type `scholia.toml` exits 2 naming the file (M4). A dangling symlink, unreadable file or directory named `*.md` is skipped with one stderr line (M6).
- **How a user reaches it:** by accident: a synced or read-only vault, an editor's broken symlink, a typo in `scholia.toml`.
- **Drive it:** `verify/verify verify index-faults`.
- **What usually lies:** a read-only vault with no current index is searchable but pays a full build on every run, because the rebuilt index cannot be saved.
