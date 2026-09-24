# Capture workflow

How a link / file / PDF becomes a connected note in this vault. The whole flow is automated by the **`/capture-nt`** skill ([scholia](https://github.com/NakliTechie/scholia) `skills/capture-nt/`, installed to `~/.claude/skills/capture-nt/`); this doc is the human-readable spec it implements — and the manual fallback when you'd rather do it by hand.

## The flow

```
drop  →  fetch/extract  →  follow & summarise embedded links  →  source note (+ realm)  →  link into topics + backlinks  →  (optional) promote a synthesis note  →  commit + push
```

### 1. Drop
Hand `/capture-nt` a **URL** or a **file path**:
```
/capture-nt https://example.com/some-article
/capture-nt ~/Downloads/some-paper.pdf
```
No time to process? Drop a one-liner in `inbox/` and move on:
```bash
echo "https://example.com/read-later" > inbox/2026-06-21-read-later.md
```
Dropping a **PDF / doc** straight into the vault works too — put the file in `assets/` (or `inbox/`) and point `/capture-nt` at the path. Add a realm word when it isn't general knowledge:
```
/capture-nt ~/Downloads/q3-contract.pdf work
/capture-nt ~/Downloads/lab-results.pdf personal
```

### 1b. Orient — before fetching
The cheap step that saves the expensive one. `/capture-nt` runs it first:
```bash
scholia orient <url-or-path>
```
It answers three things at once: **have we got this already** (if so the capture is an *update* — refresh the existing note in place, never write a second one), **what is it near** (the neighbours the new note should link to), and **what should it be labelled** (the tags those neighbours already carry — reuse before coining). It also names the likely topic MOC, so step 5 is decided before the note is written.

This is what stops the two failure modes that actually happen: fetching a source the vault already holds, and filing it under a brand-new tag nobody else uses.

### 2. Fetch / extract
Pick the tool by source type — the goal is readable text + key media, not raw HTML:

| Source | Tool |
|--------|------|
| Open web page / article | **WebFetch** |
| Login-gated site (x.com, paywalled, LinkedIn, …) | **Chrome MCP** (`mcp__Claude_in_Chrome__*`) — drives your logged-in browser |
| PDF | the **`pdf`** skill |
| Word / `.docx` | the **`docx`** skill |
| Video | transcript via the page; else note title + description and flag the gap |
| Repo | WebFetch the README; record the repo URL |

### 3. Follow & summarise the embedded links (especially listicles)
Many captures are **pointers, not destinations** — a listicle ("10 tools that…"), a link roundup, a thread of resources. The value is the linked content, not the framing. So `/capture-nt` follows them (one hop) and records a **verified one-line summary** per item, replacing the author's framing with first-hand facts:
- **GitHub repos** → real stars + license via `gh` (listicle counts are often rounded / stale).
- **Pages / PDFs** → a one-line gist via WebFetch / the `pdf` skill.
- **Gated links** → via the Chrome MCP, or marked `(not followed — gated)`.

It caps at ~15 links, notes anything skipped, and **flags discrepancies** (e.g. "claimed 51K → verified 69K"). For a plain article that just cites a few links, it follows only the load-bearing ones. These summaries land in the note's `## Key claims & data`.

### 4. Write the source note
Create `sources/YYYY-MM-DD-slug.md` with the full frontmatter and body sections (see [README.md](README.md#source-note-frontmatter)). Capture _what the source said_ — claims, numbers, quotes — not your opinion of it. Tag its **realm** in `domain:` — `knowledge` (default), `personal`, `work`, or `ventures`. A `personal` note also gets the tag `private`, a `work` note the tag `work`. Set `status: processed` once the body is filled in (`inbox` while it's still a stub). Save any large binary (PDF, image) under `assets/` and link to it. Save the extracted text of **every** source as `assets/<slug>.txt` and link it as `Full text:` under the title: when the URL dies, the text survives (text only, no page prints).

Give each **load-bearing claim** a block ID at the end of its bullet line, `- … ^claim-id` (lowercase kebab, unique in the file). Three to five per source is typical; skip it for a thin note. The IDs let notes cite the claim itself, see [README.md](README.md#passage-links--cite-the-claim-not-the-file).

### 5. Link it in
- Add a one-line annotated link to the relevant **`topics/`** MOC(s). Create the MOC if the theme is new.
- Add `[[wikilinks]]` from the source's _"Why it matters / connections"_ section to related notes / sources / topics.
- When a new or updated note rests on one claim of a source, cite it as `[[source-slug#^claim-id]]`. If that claim has no block ID yet, add one to the source. `scholia doctor` flags anchors that do not resolve.
- Backlinks are free — anything that `[[links]]` to this note is findable with `rg`.

### 6. (Optional) Promote a synthesis
If the source changed your thinking, or combines with others into a reusable insight, write an **evergreen note** in `notes/` — in _your_ voice — and link it back to the source(s). This is the payoff: your own knowledge compounding, decoupled from any single source.

### 7. Commit & push (automatic)
`/capture-nt` saves as it goes — it stages the vault's content dirs, commits (`Capture: <title>`), and pushes to the private remote. No manual step, no waiting. ## Idempotency
`/capture-nt` is idempotent-ish: before creating a note it greps `sources/` for the `url:` you gave. If a note for that URL already exists, it **updates** that note instead of creating a duplicate. Re-running on the same link is safe — use it to refresh a source you've revisited.

## Status lifecycle
```
inbox  →  processed  →  evergreen
```
- `inbox` — captured but not yet distilled (a stub, or a raw extract).
- `processed` — the source note is complete: TL;DR, claims, quotes, links.
- `evergreen` — its insight has been promoted into a `notes/` note (the source note stays as the record).

## Doing it by hand
Everything above is just files. Copy an existing source note as a template, fill the frontmatter, write the sections, add the links. The slash command saves keystrokes; it isn't required.
