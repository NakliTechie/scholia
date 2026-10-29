# freshness

- **What exists:** each command stats every content file (name, size, mtime, ctime, inode) and rebuilds only when the stamp changed; `scholia build` always rebuilds. An index built within 2 s (`RACY_NS`) of the newest mtime is stored untrusted and rebuilt once more.
- **How a user reaches it:** implicitly, on every command.
- **Drive it:** `verify/verify verify freshness` (fresh sessions read back the same index and see edits; a cached answer equals a forced rebuild's).
- **What usually lies:** `tests/smoke.sh` sleeps 2.2 s to leave the racy window; raising `RACY_NS` to 3 s fails its "unchanged vault keeps its index" check every time, so the sleep must track the constant. `tests/fresh_fuzz.py` found no stale index in 150 runs even with the racy rule off, because ctime and inode catch each edit on APFS.
