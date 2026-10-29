# search

- **What exists:** BM25 search over title, aliases, tags, TL;DR and body; British and American spellings both match; all terms first, then any term, and the header says which. Filters: `--kind --tag --realm --type --status --since`.
- **How a user reaches it:** `scholia search <terms>` from inside a vault, or with `--vault`.
- **Drive it:** `verify/verify verify search`.
- **What usually lies:** scores of `0.0` on a tiny vault are BM25 with a term in most notes, not a bug. `--since` takes a real date only (L3); `--limit` takes 1 or more (L4). Only stopwords exits 1 with `no searchable terms`.
