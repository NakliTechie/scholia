# Changelog

## Unreleased

- **orient:** finds a URL anywhere in the target, so `orient "<url> <title words>"` reports ALREADY CAPTURED. Before, extra words after the URL made the duplicate check miss.

## v0.1.0 — 2026-09-24

First release, spun out of a private vault's `bin/vaultdb.py` and ntkit's `capture-nt` / `ask-nt` skills.

- **Engine:** `bin/scholia` — a stdlib SQLite FTS5 index rebuilt from the Markdown on every run, written to a temp file and renamed into place so parallel runs never see a half-built index. Commands: search, related, orient, semantic, entity, backlinks, tags, doctor, linkcheck, stats, build.
- **Vault discovery:** `--vault DIR`, then `SCHOLIA_VAULT`, then the nearest parent holding `sources/` and `notes/`. Optional `<vault>/scholia.toml` lists other markdown folders the vault links into (`memory_dirs`).
- **Caches renamed:** `.scholia.db` and `.scholia.emb.db` in the vault (were `.vault.db`, `.vault.emb.db`); the embedding model lives in `~/.cache/scholia/models`.
- **Ranking, measured on 30 labelled questions:** search ranks all-term matches first and fills the remaining slots with any-term matches, and matches British and American spellings (recall@10 0.615 → 0.765 on 20 tuning questions, 0.483 → 0.733 on 10 held-out). `related` damps links to hub notes by degree (hub share of top-8 slots 13.0% → 9.6%).
- **Passage links:** `[[source#^claim-id]]` citations are parsed; `doctor` flags anchors that do not resolve.
- **Skills:** `/capture-nt` (saves a text snapshot of every source; realm tags for personal/work notes) and `/ask-nt` (a bounded search loop of at most 4 rounds with a `Rounds: n/4` footer).
- **Template vault** and `tests/smoke.sh` (14 checks).
