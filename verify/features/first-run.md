# first-run

- **What exists:** with no vault, every vault command exits 2 with `no vault found` and how to point at one. A `--vault` or `SCHOLIA_VAULT` that holds none of `sources/ notes/ topics/ glossary/` exits 2 with `not a vault:` (M3), so no `.scholia.db` lands in a home folder. A template copy runs every command on zero notes.
- **How a user reaches it:** the README install: copy `template/`, then `scholia stats`.
- **Drive it:** `verify/verify verify first-run`.
- **What usually lies:** `stats` on zero links used to print `None` (M1). `scholia-eval` on the template's comment-only `eval/queries.tsv` exits 2 with what to add (M2); that is correct, not a failure. `backlinks <missing>` exits 1 with a message by design.
