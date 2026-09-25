#!/bin/sh
# Smoke test: build a throwaway vault from template/, add two notes, and check
# every command against it. Offline; needs only python3 (3.11+). Exit 0 = pass.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
S="$here/bin/scholia"
v=$(mktemp -d)
trap 'rm -rf "$v"' EXIT
cp -R "$here/template/." "$v/"
pass=0
fail=0
check() { # check <description> <expected substring> <command...>
  desc=$1; want=$2; shift 2
  out=$("$@" 2>&1) || true
  case $out in
    *"$want"*) pass=$((pass + 1)); echo "ok   $desc" ;;
    *) fail=$((fail + 1)); echo "FAIL $desc"; echo "     wanted: $want"; echo "$out" | sed 's/^/     | /' | head -8 ;;
  esac
}

cat > "$v/sources/2026-01-01-example-paper.md" <<'EOF'
---
title: "Example paper on licence terms"
url: https://example.com/paper
source_type: pdf
captured: 2026-01-02
published: 2026-01-01
tags: [licensing, example]
status: processed
---
## TL;DR
A paper about open-source licence choices.

## Key claims & data
- MIT is the most common licence in the sample of 1,000 repos. ^mit-most-common
- Copyleft share fell from 30% to 18% over five years. ^copyleft-share

## Why it matters / connections
- [[licensing-notes]]
EOF
cat > "$v/notes/licensing-notes.md" <<'EOF'
---
title: Licensing notes
tags: [licensing]
status: evergreen
created: 2026-01-03
---
Permissive licences dominate ([[2026-01-01-example-paper#^mit-most-common]]).
A broken anchor: [[2026-01-01-example-paper#^no-such-claim]].
EOF

cd /tmp
check "no vault -> exit 2 with a hint" "no vault found" "$S" stats
check "stats counts notes"           "sources     1 notes"   "$S" --vault "$v" stats
check "stats counts passage links"   "2 [[note#anchor]] · 1 resolve" "$S" --vault "$v" stats
check "search: American spelling finds British text" "example-paper" "$S" --vault "$v" search license
check "search via SCHOLIA_VAULT"     "example-paper" env SCHOLIA_VAULT="$v" "$S" search copyleft
check "search from inside the vault" "example-paper" sh -c "cd '$v/notes' && '$S' search copyleft"
check "related finds the linked note" "licensing-notes" "$S" --vault "$v" related 2026-01-01-example-paper
check "orient reports a known url"   "ALREADY CAPTURED" "$S" --vault "$v" orient https://example.com/paper
check "orient finds a url among extra words" "ALREADY CAPTURED" "$S" --vault "$v" orient https://example.com/paper Example Paper licensing
check "orient without a url skips the check" "no URL given" "$S" --vault "$v" orient Example Paper licensing
check "doctor flags the broken anchor" "#^no-such-claim" "$S" --vault "$v" doctor
check "backlinks show the cited anchor" "cites: #^mit-most-common" "$S" --vault "$v" backlinks 2026-01-01-example-paper
check "entity lists the naming passage" "MIT is the most common" "$S" --vault "$v" entity MIT
check "tags lists counts"            "2  licensing" "$S" --vault "$v" tags
check "semantic without fastembed -> install hint" "needs fastembed" python3 -S "$S" --vault "$v" semantic licence

# Concurrency: parallel rebuilds must never see a half-built index.
errs=0
for i in 1 2 3 4 5 6 7 8; do ("$S" --vault "$v" stats >/dev/null 2>"$v/.err$i" || echo x >>"$v/.fails") & done
wait
if [ -s "$v/.fails" ] || grep -q Error "$v"/.err*; then
  fail=$((fail + 1)); echo "FAIL 8 parallel rebuilds"
else
  pass=$((pass + 1)); echo "ok   8 parallel rebuilds"
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
