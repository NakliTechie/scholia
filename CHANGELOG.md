# Changelog

## Unreleased

### Added
- **The semantic extra lives in its own venv.** Installing `requirements-semantic.txt` into a shared Python upgraded about 20 of its packages and broke other tools' pins. `scholia` now looks for a private venv (`~/.local/share/scholia/venv`, or `$SCHOLIA_VENV`); when the running Python lacks fastembed and that venv exists, `semantic`, `related --semantic` and `orient --semantic` re-run under the venv's interpreter, once. The install hint and the README give the two setup commands. 2 new smoke checks, plus one that runs only when the venv is present (66 total on a machine with the venv and model).

- **A read-only vault is searchable.** When `.scholia.db` cannot be written (a read-only vault, or a directory at that path), every read command builds the index in memory for that run and prints one stderr line naming the path; before, it exited 2. The cost is a full build on every run, because nothing is cached. `scholia build` still exits 2 there, since its job is to write the index. `semantic` does the same for its embeddings file: it works on an in-memory copy, seeded from the file when one exists, so only missing passages are embedded. 5 new smoke checks (64 total; the 2 semantic ones run only when fastembed and its model are installed); the walkthrough harness covers both cases and the `build` refusal (66 steps).

- **orient and the index know the glossary.** `glossary/` is indexed beside sources, notes and topics: a term's `aliases` are searchable with its title, its `summary` stands in for a TL;DR, and links from topic MOCs to terms now resolve (on the author's vault, `doctor` flags fell 288 → 286). `orient` prints a last block, `== glossary terms ==`, with matching terms and their summaries, so `/capture-nt` Step 7b maps to an existing term before writing a new one; terms never take a slot in the neighbour list. `search --kind glossary` finds terms. `doctor` does not count an untagged term as thin metadata. 3 new smoke checks (59 total).

- **/capture-nt:** new Step 7b maps each capture's key terms (usually 1–5) to the vault glossary: an existing term, found by title or alias, gains the new source on its `Source:` line; a missing one gets a plain-English `glossary/<term>.md` listed under the topic MOC's `## Glossary`. Skipped when the vault has no `glossary/` folder and for `personal` or `work` captures. Step 9 commits `glossary/` files; the confirm echo gains a `glossary:` line. The template vault gains a `glossary/` folder and the glossary-term frontmatter.

- **/panel-nt (new skill):** put one question to several different models and synthesise the answers. A stdlib runner (`skills/panel-nt/scripts/panel.py`) launches each provider with no stdin, a timeout and its own process group; providers that share local state run one at a time (`group`); `--probe` drops providers that fail a trivial first call; one serial retry for errors; `status.json` records the outcome. The skill adds the prompt template, a privacy rule (third-party providers see public material only), subagent panels with the asker's own answer written first, and synthesis rules (cluster, rank by independent support, keep kill conditions, verify one hook per top idea, state premise problems first). New smoke checks cover timeouts, groups, retry and probe.

- **history (new):** `scholia history <terms>` searches one ntkit `plan/` folder, `_archive/` and `lab/` included, and needs no vault. `history.md` and `_archive/` only grow, so this answers "when and why did we drop X?" without reading them by hand. Each top-level bullet or paragraph is one entry, dated from its own text, else its nearest dated heading, else its file name. BM25 order, or newest first with `--chrono`; `--since` and `--until` filter on the entry date. All terms first, then any term, with a one-line note. `--plan DIR` takes a repo root or its `plan/` folder and follows symlinks. `main()` now skips the vault lookup for commands that set `needs_vault=False`; every other command is unchanged. 13 new smoke checks (35 total). The section heading is indexed at half weight, so a term that appears only in a heading still finds its entries.

- **Skip the rebuild when nothing changed.** Every command used to rebuild the whole index (about 450 ms on a 1,394-file vault). It now takes one `stat` of every content file (name, size, modification time, change time and inode), this script and the memory note names, hashes them, and compares the digest stored in the index (`meta` table). Unchanged: the index is reused (search 448 ms → 43 ms, 10.4x, median of 10 runs on the author's machine; the interpreter alone is about 20 ms of that). Changed: a full rebuild as before; a one-edit run is 1.2% slower and a touch on every file 4.8% slower than before. Git's racy rule applies: an index built while any file's mtime was within 2 s of the build start is stored as untrusted and rebuilt once more on the next run, so a same-size edit inside one timestamp tick is never missed. `scholia build` always rebuilds. The change time (ctime) is in the stamp because `utime` and `cp -p` cannot set it back: an outlier idea from the first panel run ("metadata alone is insufficient: test restored-timestamp edits") showed that a same-size edit with the old mtime put back was missed by an mtime-and-size stamp; with ctime it is seen, and only a forged ctime would hide a change (`scholia build` always rebuilds). New smoke checks (7; 56 total) and `tests/fresh_fuzz.py`, which applies random edits, adds, deletes, renames, touches and restored-mtime edits and compares the skipped state with a full rebuild.

- **/panel-nt outliers.** A panel's consensus measures obviousness, so ideas that only one answer proposed are now handled on purpose. The prompt asks each model for a labelled WILDCARD (the idea it expects the others to miss, with why). Synthesis gains an outlier pass: log every singleton in `outliers.md`, check one hook each, judge on four checks (hook, cheap test, distance from the consensus, stakes) with a blind judge of another family in full mode and never the proposer, run any one-command test at once, promote at most two as "Worth a look", and keep a status ledger (`open`, `tested`, `useful`, `dead`) so each model's hit rate on outliers can be counted over runs. In the first trial a judge-promoted outlier measured no gain, while a lower-scored one exposed a hole in the code the panel had inspired.

- **/panel-nt `--mine`:** a mode for one narrow question: which published technique fits a slow or costly spot in your code. `references/mine.md` gives a five-line bottleneck statement (structure, operation, numbers, constraint, ruled out), a prompt that demands named techniques with citations, the citation as the claim to verify, and a benchmark spec per technique (baseline, worst case, a case where it should lose, win condition fixed before any run). Prompted by a report of a model recalling a known algorithm that sped up a lockfile step by up to 11,900x on hard inputs.

- **/capture-nt:** Step 10b runs `/panel-nt` in light mode, only on request (it is off by default), and no longer names models or local paths.

- **/capture-nt:** Step 9 now ends by deleting the capture's own temp files (downloads, extracts, images, scripts in the scratchpad or `/tmp`) once the commit lands; the `assets/` copy is the one kept. The confirm echo gains a `cleaned:` line. A sweep on 2026-10-09 found 621 leftover files (34 PDFs, ~220 MB) from 47 capture sessions, 27 of them byte-identical to files in `assets/`.

### Fixed
- **`semantic` on a vault with no notes.** `semantic`, `related --semantic` and `orient --semantic` raised `ValueError: need at least one array to stack` on a fresh template vault; they now report no matches. Found by a `/walkthrough-nt map` source pass; 2 harness steps pin it.
- **orient:** the duplicate check now matches a note's `alt_urls` as well as its `url`. A tweet or repo filed under its paper (the vault's canonical-capture rule) used to read as a new capture. A new `urls` table holds every URL a note answers for.
- **orient:** x.com links drop their query string (`?s=46&t=…` is share tracking), and `twitter.com` / `mobile.twitter.com` map to `x.com`. 4 new smoke checks (39 total).
- **orient:** `alt_urls` written as a YAML block list (`- url` lines) is read too. 1 new smoke check (40 total).

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
