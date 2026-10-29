# linkcheck

- **What exists:** resolves every note's `url:` (HEAD, then GET when HEAD is refused) and sorts them into ok, dead (404/410/DNS), blocked (401/403/429) and error (timeout, 5xx). The probe timeout is 10 s and not configurable.
- **How a user reaches it:** `scholia linkcheck [--workers N --all]`. It is the only command that uses the network.
- **Drive it:** `verify/verify verify linkcheck`. The harness starts a stub HTTP server on `127.0.0.1` port 0 and writes a vault whose URLs point at it; real URLs are never fetched. The DNS-failure branch is not driven (it would query a resolver).
- **What usually lies:** blocked URLs are hidden without `--all`. `--workers 0` is a usage error (L1).
