# Vault

A personal knowledge vault: plain Markdown + YAML frontmatter + `[[wikilinks]]`. Sources record what others said; notes record what you concluded; topics are hand-kept maps. Every note is written to stand alone as a search result.

Searched and checked with [scholia](https://github.com/NakliTechie/scholia): `scholia search <terms>`, `scholia doctor`. Captured with `/capture-nt`, asked with `/ask-nt`. The flow is in [CAPTURE.md](CAPTURE.md).

## Layout

| Folder | Holds | Answers |
|--------|-------|---------|
| `inbox/` | Raw, unprocessed drops. A URL in a one-line `.md` is fine. | "I'll deal with this later." |
| `sources/` | One note per **external** source (article, tweet, PDF, video, repo). What _they_ said. | "What did this source actually claim?" |
| `notes/` | Atomic **evergreen** notes — _your_ synthesis, conclusions, reusable insights. | "What do _I_ think / know?" |
| `topics/` | **MOCs** (Maps of Content) — curated hub notes per theme. | "Show me everything on X." |
| `assets/` | PDFs, saved HTML, images — the binary payloads notes point at. | "Where's the actual file?" |

## The core principle: separate source from synthesis
A **source note** records _what someone else said_ — faithfully: their claims, their data, their quotes. An **evergreen note** records _what you concluded_ — in your voice, reusable, standing on its own. They live in different folders on purpose:

- It keeps you honest about which is which (a paraphrase of one article is not your own knowledge).
- It lets your own thinking accrete **independently** of any single source.
- An evergreen note links _down_ to the source(s) that informed it; a source note links _up_ to the syntheses it feeds.

If a note reads like a summary of one thing you read, it belongs in `sources/`. If it's a conclusion that would survive that source being deleted, it belongs in `notes/`.

## Conventions

### Filenames
- **kebab-case**, always. `text-coder-plus-multimodal-qa.md`, not `Text Coder.md`.
- **Source notes are date-prefixed:** `YYYY-MM-DD-slug.md`. The date is the source's **publish date** when known, otherwise the date you captured it — so `sources/` sorts chronologically by the material's own timeline, and undated drops still sort by when they entered the vault.
- Notes and topics are **not** date-prefixed (they're timeless / continuously updated).

### Realms — knowledge · personal · work
Not everything here is "knowledge." The vault holds three realms under one roof, tagged per note by the **`domain`** frontmatter field:

- **`knowledge`** — what you're learning about the world. The **default**; an absent `domain` means this.
- **`personal`** — your own life: health, money, home, family, travel.
- **`work`** — a job, client, or employer (someone else's shop).

One field, not three folders — so a note can still link _across_ realms, and you slice by realm with a grep:
```bash
rg -l "^domain: work" sources/ notes/         # everything work
rg --files-without-match "^domain:" sources/  # untagged ⇒ knowledge by default
```
`domain` lives on **sources and notes** (the content); topic MOCs are cross-cutting and don't carry one.

**Privacy:** keep the vault in a private repo. A `personal` note also carries the tag **`private`**; a `work` note carries the tag **`work`**. `scholia doctor` flags any that miss it, so `rg -l "private" sources/ notes/` always finds the sensitive set. If something genuinely sensitive lands, `domain` and these tags are what you would filter on.

### Source-note frontmatter
```yaml
---
title:
url:
author:
source_type: article|tweet|pdf|video|repo|doc
captured: 2026-06-21      # the day it entered the vault
published:                # the source's own date, if known
domain: knowledge         # realm: knowledge | personal | work  (absent ⇒ knowledge)
tags: []
status: inbox|processed|evergreen
rating:                   # optional — your call, e.g. 1–5
---
```
Body sections, in order:
- `## TL;DR` — ≤3 lines. The whole thing, compressed.
- `## Key claims & data` — bullets. The load-bearing facts and numbers, preserved exactly. A claim that a note cites, or is likely to, ends in an Obsidian **block ID**: `- **Result:** ranked #1 on … ^design-arena-rank-1` (see **Passage links** below).
- `## Quotes` — short, verbatim, **attributed**. Don't paraphrase here; if you couldn't get the full text, say so rather than inventing.
- `## Why it matters / connections` — `[[wikilinks]]` to notes, topics, other sources.
- `## Open questions` — what it leaves unresolved.
- Raw link(s) at the bottom.

### Evergreen-note frontmatter
```yaml
---
title:
tags: []
status: evergreen
domain: knowledge          # knowledge | personal | work
created: 2026-06-21
---
```
Body = the reusable insight, **in your voice**, linking to its source(s) via `[[...]]`.

### Topic MOC frontmatter
```yaml
---
title:
type: moc
tags: []
updated: 2026-06-21
---
```
Body = a curated index that links the relevant sources and notes, each with a **one-line annotation** saying why it's there. A MOC is hand-tended, not auto-generated — the curation _is_ the value.

### Linking
- `[[slug]]` — wikilink by filename without the `.md` (`[[text-coder-plus-multimodal-qa]]`).
- Link **liberally.** A `[[link]]` to a note that doesn't exist yet is fine — it marks something worth writing later.
- Backlinks are implicit: `rg "\[\[this-slug\]\]"` finds everything pointing at a note.

### Passage links — cite the claim, not the file
A whole-file link says "somewhere in this source." When a note leans on one specific claim, point at the claim:
- **In the source note**, end the claim's bullet line with a block ID: a space, `^`, then lowercase kebab (`^benchmark`, `^five-moves`). IDs are unique within the file, describe the claim, and never change once cited.
- **In the citing note**, link `[[source-slug#^block-id]]`. A section link, `[[source-slug#Key claims & data]]`, also works.
- It is plain Obsidian syntax: Obsidian jumps to the passage, and `rg "\^benchmark"` finds it without Obsidian.
- Add IDs when a claim gets cited, not in bulk. Never rewrite old links wholesale.
- `scholia doctor` lists any `#^block` or `#heading` that the target note does not have; `stats` counts passage links.

### Tags
Lowercase kebab, in the `tags:` array. Reuse an existing tag before coining a new one. Tags are a coarse filter; `topics/` MOCs are the curated index.

## Browsing without any tool
```bash
rg -l "term"                          # files mentioning a term
rg "\[\[slug"                         # backlinks to a note
rg -l "status: inbox" sources/ notes/ # the triage queue
ls sources/ | sort                    # every source, chronological
```
Obsidian works as an optional lens: point it at this folder. Nothing here needs it.
