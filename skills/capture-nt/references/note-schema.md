## Step 5 — Derive metadata
- **slug** — kebab-case from the title (drop stopwords; short and recognizable; avoid a leading number right after the date prefix).
- **date prefix** — the source's **publish date** (`YYYY-MM-DD`) if discoverable, else today. Filename: `sources/<date>-<slug>.md`.
- **source_type** — `article|tweet|pdf|video|repo|doc|chat-session`, inferred (x.com `/status/` → `tweet`; `/i/article/` → `article`; `.pdf` → `pdf`; `github.com` → `repo`; `.docx` → `doc`; `claude.ai/share/` → `chat-session`).
- **chat-session extras** — title from the shared chat's title if extractable, else the first user message (truncated); **date prefix = the conversation's date**, not the capture date; set `platform` (`claude.ai` for now — the field future-proofs other assistants), `session_date`, and `capture_mode` (`share-url` | `capture-file`) in the frontmatter.
- **domain** — which **realm** this belongs to: **`knowledge`** (general learning — the default), **`personal`** (your own life: health, money, home, family), or **`work`** (a job / client / employer). If the user named a realm in the invocation, use it; else infer from the content. Set it when it's clearly personal or work; default `knowledge` when unsure — and if the content looks **sensitive** (a statement, a contract, medical), ask before filing. (Absent ⇒ `knowledge`.) A `personal` note also gets the tag **`private`**, a `work` note the tag **`work`**; `scholia doctor` flags any that miss it.
- **tags** — reuse existing tags first:
  ```bash
  grep -rhoE 'tags: \[.*\]' "$VAULT/sources" "$VAULT/notes" "$VAULT/topics" | tr ',[]' '\n' | sed 's/tags://; s/ //g' | grep -v '^$' | sort | uniq -c | sort -rn
  ```
  Coin a new tag only when nothing fits.
- **author**, **published** — from the page metadata when present.

## Step 6 — Write the source note
Write (or rewrite, if updating) `sources/<date>-<slug>.md` using the vault's source schema:
```yaml
---
title:
url:
author:
source_type: article|tweet|pdf|video|repo|doc|chat-session
captured: <today>
published:
domain: knowledge        # knowledge | personal | work
tags: []
status: processed        # 'inbox' if it's only a stub
rating:
platform: claude.ai      # chat-session only — which assistant hosted the conversation
session_date: YYYY-MM-DD # chat-session only — date of the conversation, not the capture
capture_mode: share-url  # chat-session only — share-url | capture-file
---
```
The three `chat-session` fields appear **only** on chat-session notes. Never rewrite existing notes to backfill fields — old notes stay untouched.
Then the body, in order — **record what the source said, not your opinion of it:**
- `## TL;DR` — ≤3 lines.
- `## Key claims & data` — bullets; preserve concrete numbers; fold in the **followed-link summaries** from Step 4. End each **load-bearing** claim's bullet line with an Obsidian block ID — a space, `^`, lowercase kebab, unique in the file (`- **Result:** ranked #1 … ^design-arena-rank-1`). Three to five per source; skip for a thin note. IDs never change once cited.
- `## Quotes` — short, verbatim, attributed. If you couldn't get the full text, say so here rather than inventing quotes.
- `## Why it matters / connections` — `[[wikilinks]]` to related notes / sources / topics.
- `## Open questions`.
- Raw link(s) at the bottom.

For a **chat session**, the body keeps the **Human/Assistant turn structure** (condensed is fine — the alternation is the content, so don't flatten it into a summary), and adds `## References mentioned` — the URLs the conversation touched, one line each, not deep-indexed (Step 4).

**Every source gets a text snapshot:** save the extracted text to `$VAULT/assets/<slug>.txt` and put `Full text: [<slug>.txt](../assets/<slug>.txt)` under the title, so a dead URL loses nothing. Text only; no HTML or PDF prints of web pages.

For a **dropped PDF / doc / image**, keep the file under `$VAULT/assets/` and point the note at it with a relative link (`[paper.pdf](../assets/paper.pdf)`); the note carries the TL;DR + claims, so the vault stays searchable without opening the binary.

## Step 7 — Link it into the graph
- Pick the right **topic MOC(s)** in `$VAULT/topics/`. Reuse an existing one (`ls "$VAULT/topics/"`); create `topics/<theme>.md` only if the theme is genuinely new (MOC frontmatter: `title`, `type: moc`, `tags`, `updated`). Add a **one-line annotated link** to the new source under the MOC's `## Sources`.
- **Passage links.** When a note (new or updated) rests on one claim of a source, cite `[[source-slug#^claim-id]]`, not the bare file. If the claim has no block ID yet, add one to the source. Do not rewrite existing links in bulk. `scholia --vault "$VAULT" doctor` lists `#^block` / `#heading` anchors that do not resolve; run it after writing.
- Make sure the source's _"Why it matters / connections"_ section links back (`[[...]]`) to those topics and any related notes — backlinks are just `rg "\[\[<slug>\]\]"`.
- Bump the MOC's `updated:` date.

## Step 7b — Map terms to the glossary
Skip this step when `$VAULT/glossary/` does not exist (the vault does not keep a glossary), or when the capture's `domain` is `personal` or `work`. Otherwise, every capture maps its terms to glossary entries:

1. **Pick the terms.** Choose the technical terms a reader would look up and that this source explains or uses centrally: usually 1–5. Skip everyday words and terms the source only mentions in passing.
2. **Map before creating.** For each term, search titles and aliases:
   ```bash
   rg -il -e "^title: .*<term>" -e "^aliases: .*<term>" "$VAULT/glossary/"
   ls "$VAULT/glossary/"
   ```
   Try the abbreviation and the spelled-out form. A match is the same entry: add `[[<source-slug>]]` to its `Source:` line, add the term's topic to `topics:` if missing, and change nothing else unless the source corrects the definition. When it does, edit the definition and say so in the confirm.
3. **Create what is missing.** Write `glossary/<term-kebab>.md` with the vault's glossary frontmatter (`$VAULT/README.md` → Glossary-term frontmatter): `title` as a reader would look it up, `aliases` (abbreviations, plurals, other spellings), a one-sentence `summary`, `topics` (the MOC Step 7 used), `related` (other glossary slugs), `domain: knowledge`, `added`. Body: one to three short paragraphs in plain English (what it is, why it matters, how it differs from its neighbours), then `Source: [[<source-slug>]]`. The filename has no date and must differ from every source, note and topic filename.
4. **Write for anyone.** A glossary may be published, so a definition names no local paths, private projects, private people or vault-only labels. Describe the idea, not this capture.
5. **List new terms in the MOC.** Add one line per new term under the topic MOC's `## Glossary` heading (create the heading above `## Sources` or the MOC's notes section if it is missing): `- [[<term>]] — <short gloss>`.

## Step 8 — Optional: promote a synthesis
If the source genuinely shifts the user's thinking, or combines with existing notes into a reusable insight, offer to write an **evergreen note** in `notes/` — in the _user's_ voice, `status: evergreen`, same `domain`, linking down to the source(s). Don't force it: most captures are just sources. Ask before creating, unless the user already said to.

**Chat capture files are the exception that earns the offer by default:** a capture file is already a distillation — the "what I concluded" side, not raw source material. After filing it as a `chat-session` source, offer to promote it straight to `notes/` in the same pass. Ask; don't assume.
