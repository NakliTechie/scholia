# scholia feature map

Read by the next `/walkthrough-nt`, `/autopilot-nt` and `/guide-nt`. Each file says what exists, how a user reaches it, how to drive it with the harness, and what usually lies. Sweep order:

| Feature | Surface | Harness |
|---|---|---|
| [first-run](first-run.md) | no vault, a fresh template vault | `verify/verify verify first-run` |
| [search](search.md) | `scholia search` | `verify/verify verify search` |
| [orient](orient.md) | `scholia orient` | `verify/verify verify orient` |
| [graph](graph.md) | `related`, `backlinks`, `entity`, `tags` | `verify/verify verify graph` |
| [doctor](doctor.md) | `scholia doctor` | `verify/verify verify doctor` |
| [projects](projects.md) | `scholia projects` | `verify/verify verify projects` |
| [history](history.md) | `scholia history` (no vault) | `verify/verify verify history` |
| [linkcheck](linkcheck.md) | `scholia linkcheck` (network) | `verify/verify verify linkcheck` |
| [eval](eval.md) | `scholia-eval` | `verify/verify verify eval` |
| [index-faults](index-faults.md) | index and config on a hostile disk | `verify/verify verify index-faults` |
| [semantic](semantic.md) | `scholia semantic`, `--semantic` | `verify/verify verify semantic` (embedding path only with the host venv and model) |
| [freshness](freshness.md) | skip-rebuild and read-back | `verify/verify verify freshness` |

The harness needs Python 3.11+ with SQLite FTS5, `tmux`, `git` and `sqlite3`; `verify/verify doctor` checks each.

Roles: the **anonymous visitor** (no vault, no `SCHOLIA_VAULT`), the **brand-new user** (a template copy with no notes), the **vault owner** (the demo seed), the **plan-only user** (`history`, no vault). scholia has no auth, so there is no privileged role; the nearest guard is that nothing writes outside the vault.

Seed: `demo/seed/vault` (3 sources, 2 notes, 2 topic MOCs, 2 glossary terms, 3 labelled questions), `demo/seed/projects` (2 projects for `projects --dir`), `demo/seed/plan-history` (copied to `repo/plan` for `history`; it is not named `plan/` so a plan-sync tool never adopts it).

`/panel-nt`'s runner (`skills/panel-nt/scripts/panel.py`) is a second surface; `tests/smoke.sh` drives it with fake providers and this harness does not.
