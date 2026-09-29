# Changelog

## Unreleased

### Added
- **history (new):** `scholia history <terms>` searches one ntkit `plan/` folder, `_archive/` and `lab/` included, and needs no vault. `history.md` and `_archive/` only grow, so this answers "when and why did we drop X?" without reading them by hand. Each top-level bullet or paragraph is one entry, dated from its own text, else its nearest dated heading, else its file name. BM25 order, or newest first with `--chrono`; `--since` and `--until` filter on the entry date. All terms first, then any term, with a one-line note. `--plan DIR` takes a repo root or its `plan/` folder and follows symlinks. `main()` now skips the vault lookup for commands that set `needs_vault=False`; every other command is unchanged. 12 new smoke checks (34 total).

## v0.2.0 — 2026-09-28

A capture now ends by saying where it matters: in the vault, and in your projects.

### Added
- **projects (new):** `scholia projects <slug | text>` ranks the user's projects by a note's distinctive terms, so a capture can end by saying where it matters. Roots come from `project_dirs` in `scholia.toml` (or `--dir`). Each project's current state is read: `README.md`, `plan/pending.md`, `plan/workplan.md`. Records (history, dated summaries) are skipped; on the author's machine they are 83% of plan text. Terms found in more than 20% of projects, citation boilerplate and bare numbers are ignored. A project that already cites the source is marked. 210 projects with those files, searched in about 0.3 s warm (0.9 s cold). 6 new smoke checks (22 total).
- **/capture-nt:** new Step 10, Relevance. It names the closest vault notes from Step 2 and runs `projects`; it reports kept projects with one line on why, and writes to a project only on "note for <project>".
- **marketing:** a 1280×640 social card (`marketing/social.png`, rendered from `social.html` by `render-social.sh`), and a 40-second promo video (`marketing/launch.mp4`, poster `launch.jpg`).

### Changed
- **search internals:** `fts_query` now builds on `fts_terms`; `scholia-eval` output is unchanged.
- **template:** `doctor` references in the template vault point at scholia.

### Fixed
- **orient:** finds a URL anywhere in the target, so `orient "<url> <title words>"` reports ALREADY CAPTURED. Before, extra words after the URL made the duplicate check miss.
- **orient:** with no URL in the target, says the duplicate check was skipped instead of claiming no note matches. `/capture-nt` now runs its by-hand fallback in that case.

## v0.1.0 — 2026-09-24

First release, spun out of a private vault's `bin/vaultdb.py` and ntkit's `capture-nt` / `ask-nt` skills.

- **Engine:** `bin/scholia` — a stdlib SQLite FTS5 index rebuilt from the Markdown on every run, written to a temp file and renamed into place so parallel runs never see a half-built index. Commands: search, related, orient, semantic, entity, backlinks, tags, doctor, linkcheck, stats, build.
- **Vault discovery:** `--vault DIR`, then `SCHOLIA_VAULT`, then the nearest parent holding `sources/` and `notes/`. Optional `<vault>/scholia.toml` lists other markdown folders the vault links into (`memory_dirs`).
- **Caches renamed:** `.scholia.db` and `.scholia.emb.db` in the vault (were `.vault.db`, `.vault.emb.db`); the embedding model lives in `~/.cache/scholia/models`.
- **Ranking, measured on 30 labelled questions:** search ranks all-term matches first and fills the remaining slots with any-term matches, and matches British and American spellings (recall@10 0.615 → 0.765 on 20 tuning questions, 0.483 → 0.733 on 10 held-out). `related` damps links to hub notes by degree (hub share of top-8 slots 13.0% → 9.6%).
- **Passage links:** `[[source#^claim-id]]` citations are parsed; `doctor` flags anchors that do not resolve.
- **Skills:** `/capture-nt` (saves a text snapshot of every source; realm tags for personal/work notes) and `/ask-nt` (a bounded search loop of at most 4 rounds with a `Rounds: n/4` footer).
- **Template vault** and `tests/smoke.sh` (14 checks).
