<h1 align="center">scholia</h1>

<p align="center">
  <strong>A commonplace book for the agent era: capture what you read into plain Markdown, then search it, check it, and ask it with citations.</strong>
</p>

<p align="center">Python 3.11 standard library. macOS, Linux. No server, no daemon, no account, no telemetry. Markdown is the source of truth.</p>

<p align="center">
  <img alt="license: MIT" src="https://img.shields.io/badge/license-MIT-0891b2?style=flat-square">
  <img alt="dependencies: stdlib" src="https://img.shields.io/badge/dependencies-stdlib-0891b2?style=flat-square">
  <img alt="server: none" src="https://img.shields.io/badge/server-none-0891b2?style=flat-square">
</p>

## Install

| What | Command |
|---|---|
| The CLI | `git clone https://github.com/NakliTechie/scholia ~/Code/scholia && ln -s ~/Code/scholia/bin/scholia ~/Code/scholia/bin/scholia-eval ~/.local/bin/` |
| The agent skills (Claude Code) | `cp -r ~/Code/scholia/skills/* ~/.claude/skills/` |
| A new vault | `cp -R ~/Code/scholia/template ~/Code/knowledge && cd ~/Code/knowledge && git init` |

Run it anywhere inside the vault, or point at one with `--vault DIR` or `SCHOLIA_VAULT`. The first command builds an index from your Markdown in well under a second; every command rebuilds it, so it is never stale.

```bash
scholia search open source licence --limit 5
```

No config file is required and nothing runs in the background. The skills expect the vault at `~/Code/knowledge` unless `SCHOLIA_VAULT` says otherwise.

## Why

You read something worth keeping, file it somewhere, and three months later you cannot find it. Or you find it, but you can't tell whether a line in your notes is what the author said or what you concluded. Or the link is dead.

scholia keeps the old commonplace-book discipline and adds an index an agent can drive. A **source note** records what someone else said, with their numbers and quotes. A **note** records what you concluded, citing the exact claim it rests on (`[[source#^claim-id]]`). A topic map is kept by hand. `/capture-nt` checks the vault before it fetches, writes the source note, and saves the extracted text so a dead link loses nothing. `/ask-nt` answers only from the vault, in at most four search rounds, and cites every note it used.

**Use something else if** you want an agent memory that runs itself: [gbrain](https://github.com/garrytan/gbrain) runs a daemon that ingests and enriches around the clock, keeps a database as its source of truth, and serves it over MCP. If you want a graph view and editing, [Obsidian](https://obsidian.md) opens a scholia vault as-is; [VaultMind](https://github.com/NakliTechie/VaultMind) is a browser explorer for the same kind of folder. If you want to serve a Markdown folder over HTTP, see [commonplace](https://github.com/fredoliveira/commonplace).

## Cite the claim, not the file

End a load-bearing bullet in a source note with a block ID — `- MIT is the most common licence. ^mit-most-common` — and cite it from a note as `[[2026-01-01-example-paper#^mit-most-common]]`. It is plain Obsidian syntax and `rg` finds it. `scholia doctor` lists every anchor that does not resolve; `scholia backlinks <slug>` shows which claim each linking note cites; `scholia entity <name>` gathers every claim that names a lab, model or person.

## Meaning, not only keywords

Keyword search misses a note that says the same thing in other words. The optional semantic layer embeds each note's title, TL;DR and key claims with the frozen `all-MiniLM-L6-v2` encoder (about 90 MB, downloaded once to `~/.cache/scholia/models`). It needs `fastembed`, pinned in `requirements-semantic.txt`; without it, `semantic` prints an install hint and every other command runs unchanged.

```bash
uv run --no-project --with-requirements ~/Code/scholia/requirements-semantic.txt \
  ~/Code/scholia/bin/scholia semantic copying a big model into a tiny one
```

## Commands

```bash
scholia search <terms> [--kind --tag --realm --since]  # ranked: all terms first, then any term
scholia related <slug | free text> [--semantic]        # neighbours by text, tags and links
scholia orient <url | path>                            # before a capture: already held? what is near?
scholia semantic <text>                                # optional: nearest notes by meaning
scholia entity <name>                                  # every claim that names a lab, model, person
scholia backlinks <slug>                               # what links here, with the #^claim cited
scholia tags [tag]                                     # every tag with counts, or one tag's notes
scholia doctor                                         # offline hygiene worklist
scholia linkcheck                                      # network: which source urls are dead
scholia stats                                          # vault shape at a glance
scholia-eval [--queries FILE] [--impl OLD]             # score retrieval on labelled questions
```

The agent face is the two skills in `skills/`: `/capture-nt <url | file>` writes and commits; `/ask-nt <question>` is read-only.

## Verify it yourself

```bash
sh tests/smoke.sh     # 14 checks on a throwaway vault built from template/; exit 0 = pass
scholia-eval          # recall@10 and MRR@10 on <vault>/eval/queries.tsv
```

The smoke test covers vault discovery, spelling-variant search, anchor checks, backlinks, entities, the missing-fastembed path, and eight parallel rebuilds. Retrieval quality is only as good as your labels: `scholia-eval --pool` prints each question's candidates for judging, and `--impl` scores an older engine file with the same labels, so a ranking change gets a before and after.

## License

MIT. Vault conventions: [template/README.md](template/README.md) · capture flow: [template/CAPTURE.md](template/CAPTURE.md) · [CHANGELOG](CHANGELOG.md)
