# eval

- **What exists:** `scholia-eval` scores recall@10 and MRR@10 per retrieval method on `<vault>/eval/queries.tsv`, then link recall of `related` over `notes/`; `--pool` prints candidates for labelling; `--impl` scores another engine file.
- **How a user reaches it:** README "Verify it yourself".
- **Drive it:** `verify/verify verify eval`.
- **What usually lies:** with fastembed installed it also loads the embedding model (a download on first use); the harness blocks fastembed. An empty, missing or malformed label file exits 2 naming the file, and the line for a malformed row (M2). Like `scholia`, it re-runs under scholia's semantic venv when the running Python lacks fastembed, so the `semantic` and `related+sem` rows appear; `verify eval` drives that only when this host has the venv and model.
