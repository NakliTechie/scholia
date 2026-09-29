#!/bin/sh
# Smoke test: build a throwaway vault from template/, add two notes, and check
# every command against it. Offline; needs only python3 (3.11+). Exit 0 = pass.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
S="$here/bin/scholia"
v=$(mktemp -d)
p=$(mktemp -d)  # a projects root beside the vault
h=$(mktemp -d)  # a repo with an ntkit plan/ folder, for `history`
trap 'rm -rf "$v" "$p" "$h"' EXIT
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

# projects: two projects; only licence-tool shares the note's terms, and its
# pending list already cites the note's url. Its history log is a record, not
# current state, so a term found only there must not match.
mkdir -p "$p/licence-tool/plan" "$p/weather-app/plan"
printf '# licence-tool\nPicks a copyleft or permissive licence for a repo.\n' > "$p/licence-tool/README.md"
printf '## Now\n- Read https://example.com/paper on licence choices\n' > "$p/licence-tool/plan/pending.md"
printf '# weather-app\nRain forecasts on a phone.\n' > "$p/weather-app/README.md"
printf '## Log\n- licence copyleft permissive\n' > "$p/weather-app/plan/history.md"
check "projects without config -> hint" "no project directories configured" "$S" --vault "$v" projects 2026-01-01-example-paper
check "projects --dir ranks the matching project" "] licence-tool — " "$S" --vault "$v" projects 2026-01-01-example-paper --dir "$p"
check "projects flags an existing cite" "(already cites this source)" "$S" --vault "$v" projects 2026-01-01-example-paper --dir "$p"
check "projects skips record files" "searched 3 file(s) in 2 project(s)" "$S" --vault "$v" projects 2026-01-01-example-paper --dir "$p"
check "projects with a missing dir" "not found on this machine" "$S" --vault "$v" projects 2026-01-01-example-paper --dir "$p/nope"
grep -v '^project_dirs' "$v/scholia.toml" > "$v/toml.tmp"
printf 'project_dirs = ["%s"]\n' "$p" >> "$v/toml.tmp"
mv "$v/toml.tmp" "$v/scholia.toml"
check "projects reads project_dirs from scholia.toml" "] licence-tool — " "$S" --vault "$v" projects 2026-01-01-example-paper

# history: one ntkit plan/ folder, searched with no vault. marmot is only in
# _archive/ (the .txt and the >2 MB file must be skipped); quokka is on three
# dates; walrus has none. linked/plan is a symlink to repo/plan.
mkdir -p "$h/repo/plan/_archive" "$h/linked"
cat > "$h/repo/plan/history.md" <<'EOF'
# History

## Decisions
- 2026-09-20 — Dropped the zephyr exporter because nobody used it.

## Log

### 2026-09-12
- Moved the quokka parser into its own module.

### 2026-09-05
- Tried a quokka cache; too slow, reverted.

## Dead ends
- The walrus index never beat plain grep.
EOF
printf '# Summary\n\n## Decisions\nThe marmot sync was retired in favour of plain rsync.\n' > "$h/repo/plan/_archive/2026-08-01-summary.md"
printf -- '- 2026-09-08 14:32 — quokka parser feels slow on big files\n' > "$h/repo/plan/soc.md"
printf 'marmot scratch\n' > "$h/repo/plan/scratch.txt"
{ echo marmot; head -c 2200000 /dev/zero | tr '\0' x; } > "$h/repo/plan/big.md"
ln -s "$h/repo/plan" "$h/linked/plan"
dates() { "$@" | awk '/^  [^ ]/ {printf "%s ", $1}'; }  # hit dates, in order
rc() { "$@" && echo "exit=0" || echo "exit=$?"; }
check "history runs with no vault and no SCHOLIA_VAULT" "history: 1 match(es) in " env -u SCHOLIA_VAULT "$S" history marmot --plan "$h/repo"
check "history skips non-markdown and files over 2 MB" "entries in 3 files)" env -u SCHOLIA_VAULT "$S" history marmot --plan "$h/repo"
check "history finds an _archive/ entry, dated by file name" "2026-08-01  _archive/2026-08-01-summary.md:4  [Decisions]" "$S" history marmot --plan "$h/repo"
check "history dates an entry from its ### heading" "2026-09-12  history.md:9  [2026-09-12]" "$S" history parser module --plan "$h/repo"
check "history --since drops older entries" "history: 1 match(es)" "$S" history quokka --since 2026-09-10 --plan "$h/repo"
check "history --chrono lists newest first" "2026-09-12 2026-09-08 2026-09-05 " dates "$S" history quokka --chrono --plan "$h/repo"
check "history shows an undated entry as dashes" "----------  history.md:15  [Dead ends]" "$S" history walrus --plan "$h/repo"
check "history falls back to any term, and says so" "no entry matched all terms" "$S" history marmot zephyr --plan "$h/repo"
check "history follows a symlinked plan/" "_archive/2026-08-01-summary.md:4" "$S" history marmot --plan "$h/linked"
check "history defaults to ./plan" "history: 1 match(es)" sh -c "cd '$h/repo' && '$S' history marmot"
check "history without a plan folder -> message" "no plan folder found" "$S" history marmot --plan "$h/nope"
check "history without a plan folder -> exit 2" "exit=2" rc "$S" history marmot --plan "$h/nope"

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
