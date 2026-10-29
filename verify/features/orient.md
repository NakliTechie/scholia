# orient

- **What exists:** the capture pre-flight. `== idempotency ==` matches each URL against every note's `url` and `alt_urls` after normalising (tracking params, x.com share params, twitter.com to x.com); then neighbours, candidate topic MOCs and matching glossary terms.
- **How a user reaches it:** `/capture-nt` runs it first; by hand, `scholia orient <url> [words]`.
- **Drive it:** `verify/verify verify orient`.
- **What usually lies:** a URL-only target finds no glossary terms, because URL parts are not terms. `--semantic` without fastembed prints a note and runs without it (exit 0).
