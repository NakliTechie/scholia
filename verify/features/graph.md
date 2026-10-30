# graph

- **What exists:** `related` (text, tags and one-hop links, hubs damped), `backlinks` (with the `#^claim` each link cites), `entity` (key-claim passages naming a name: 15 notes and 3 passages each by default), `tags` (counts, or one tag's notes).
- **How a user reaches it:** inside a vault; `related` and `entity` take a slug or free text, `backlinks` a slug.
- **Drive it:** `verify/verify verify graph`.
- **What usually lies:** `backlinks` of an unknown slug exits 1 with `no note with slug`; that is designed. A `#` in a file name reads as a heading separator in a wikilink, as in Obsidian.
