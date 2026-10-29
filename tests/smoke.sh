#!/bin/sh
# Smoke test: build a throwaway vault from template/, add two notes, and check
# every command against it. Offline; needs only python3 (3.11+). Exit 0 = pass.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
S="$here/bin/scholia"
v=$(mktemp -d)
p=$(mktemp -d)  # a projects root beside the vault
h=$(mktemp -d)  # a repo with an ntkit plan/ folder, for `history`
sk=; pn=  # made later; one trap removes every temp dir (a second trap would replace it)
trap 'rm -rf "$v" "$p" "$h" ${sk:+"$sk"} ${pn:+"$pn"}' EXIT
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
alt_urls: [https://x.com/someone/status/123, https://github.com/example/paper]
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
# a read-only vault: search falls back to an in-memory index; `build` still refuses
rm -f "$v/.scholia.db"; chmod a-w "$v"
check "read-only vault: search works"            "example-paper"           "$S" --vault "$v" search copyleft
check "read-only vault: one stderr note"         "using an in-memory index" "$S" --vault "$v" search copyleft
check "read-only vault: build refuses"           "make the vault folder writable" "$S" --vault "$v" build
chmod u+w "$v"
check "related finds the linked note" "licensing-notes" "$S" --vault "$v" related 2026-01-01-example-paper
check "orient reports a known url"   "ALREADY CAPTURED" "$S" --vault "$v" orient https://example.com/paper
check "orient finds a url among extra words" "ALREADY CAPTURED" "$S" --vault "$v" orient https://example.com/paper Example Paper licensing
check "orient matches an alt_urls entry" "ALREADY CAPTURED" "$S" --vault "$v" orient https://github.com/example/paper
check "orient ignores x.com share params" "ALREADY CAPTURED" "$S" --vault "$v" orient "https://x.com/someone/status/123?s=46&t=abc"
check "orient maps twitter.com to x.com" "ALREADY CAPTURED" "$S" --vault "$v" orient https://twitter.com/someone/status/123
cat > "$v/sources/2026-01-05-block-list.md" <<'EOF2'
---
title: "A note with alt_urls as a block list"
url: https://example.com/block
alt_urls:
  - https://x.com/other/status/456
source_type: repo
---
## TL;DR
Block-list frontmatter.
EOF2
check "orient matches a block-list alt_urls entry" "ALREADY CAPTURED" "$S" --vault "$v" orient https://x.com/other/status/456
check "orient still says new for an unknown url" "new capture" "$S" --vault "$v" orient https://example.com/other
check "orient without a url skips the check" "no URL given" "$S" --vault "$v" orient Example Paper licensing
cat > "$v/glossary/copyleft.md" <<'EOF'
---
title: Copyleft
aliases: [share-alike, GPL-style licence]
summary: A licence that requires derived works to carry the same licence.
topics: []
related: []
domain: knowledge
added: 2026-01-02
---
A copyleft licence lets anyone reuse the code on condition that changes are shared under the same terms.

Source: [[2026-01-01-example-paper]].
EOF
check "orient lists a glossary term by its alias" "glossary/copyleft.md" "$S" --vault "$v" orient https://example.com/new share-alike
check "orient shows the term's summary" "derived works" "$S" --vault "$v" orient copyleft
check "search --kind glossary finds a term" "copyleft" "$S" --vault "$v" search copyleft --kind glossary
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

## Chunk narwhal
- Ship the settings page.
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
check "history matches a term found only in a heading" "history.md:18  [Chunk narwhal]" "$S" history narwhal --plan "$h/repo"
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

# Skip-rebuild: an unchanged vault keeps its index; any change is seen.
sk=$(mktemp -d)
cp -R "$here/template/." "$sk/"
printf -- '---\ntitle: "Skip test"\ntags: [skip]\n---\n## TL;DR\nalpha1 marker word\n' > "$sk/sources/2026-01-01-skip-test.md"
find "$sk" -name '*.md' -exec touch -t 202001010000 {} +   # old mtime; touch itself sets ctime to now
sleep 2.2   # let ctime leave the racy window, or the index is stored as untrusted
ino() { python3 -c 'import os,sys; print(os.stat(sys.argv[1]).st_ino)' "$sk/.scholia.db"; }
"$S" --vault "$sk" stats >/dev/null
i1=$(ino)
"$S" --vault "$sk" stats >/dev/null
i2=$(ino)
if [ "$i1" = "$i2" ]; then pass=$((pass + 1)); echo "ok   unchanged vault keeps its index"
else fail=$((fail + 1)); echo "FAIL unchanged vault keeps its index (inode $i1 -> $i2)"; fi
"$S" --vault "$sk" build >/dev/null
i3=$(ino)
if [ "$i2" != "$i3" ]; then pass=$((pass + 1)); echo "ok   scholia build always rebuilds"
else fail=$((fail + 1)); echo "FAIL scholia build always rebuilds"; fi
printf 'beta2 extra line\n' >> "$sk/sources/2026-01-01-skip-test.md"
check "an appended line is searchable at once" "2026-01-01-skip-test" "$S" --vault "$sk" search beta2
sed -i.bak 's/alpha1/alpha2/' "$sk/sources/2026-01-01-skip-test.md" && rm -f "$sk/sources/2026-01-01-skip-test.md.bak"
check "a same-size in-place edit right after a build is seen" "2026-01-01-skip-test" "$S" --vault "$sk" search alpha2
touch "$sk/notes/new-note-for-skip.md"
printf -- '---\ntitle: "Added"\n---\ngamma3 added later\n' > "$sk/notes/new-note-for-skip.md"
printf -- '---\ntitle: "Restore"\n---\ndelta4 marker\n' > "$sk/notes/restore-note.md"
touch -t 202001010000 "$sk/notes/restore-note.md"
"$S" --vault "$sk" stats >/dev/null
python3 - "$sk/notes/restore-note.md" <<'PYEOF2'
import os, sys
p = sys.argv[1]; st = os.stat(p); t = open(p).read()
open(p, "w").write(t.replace("delta4", "delta5"))   # same size
os.utime(p, ns=(st.st_atime_ns, st.st_mtime_ns))   # old mtime put back
PYEOF2
check "a same-size edit with the old mtime restored is seen (ctime)" "restore-note" "$S" --vault "$sk" search delta5
rm "$sk/notes/restore-note.md"
check "a new file is seen" "new-note-for-skip" "$S" --vault "$sk" search gamma3
rm "$sk/notes/new-note-for-skip.md"
check "a deleted file is gone" "no matches" "$S" --vault "$sk" search gamma3

# panel-nt runner: groups, timeout, retry, probe (fake providers; offline).
pn=$(mktemp -d)
P="$here/skills/panel-nt/scripts/panel.py"
echo "a prompt" > "$pn/prompt.md"
cat > "$pn/panel.toml" <<TOML
[defaults]
timeout = 2
retry = 1
[[provider]]
name = "fine"
cmd = ["sh", "-c", "echo PONG an answer"]
[[provider]]
name = "slow"
cmd = ["sh", "-c", "sleep 8; echo late"]
[[provider]]
name = "broken"
cmd = ["sh", "-c", "exit 3"]
[[provider]]
name = "flaky"
cmd = ["sh", "-c", "if [ -f $pn/flag ]; then echo second try; else touch $pn/flag; exit 1; fi"]
[[provider]]
name = "s1"
group = "shared"
cmd = ["sh", "-c", "echo s1 >> $pn/trace; sleep 1; echo s1 >> $pn/trace; echo ok"]
[[provider]]
name = "s2"
group = "shared"
cmd = ["sh", "-c", "echo s2 >> $pn/trace; sleep 1; echo s2 >> $pn/trace; echo ok"]
TOML
python3 "$P" run --prompt "$pn/prompt.md" --out "$pn/out" --config "$pn/panel.toml" > "$pn/table.txt" 2>&1 || true
check "panel: answered provider is ok"            "ok"              grep "^fine" "$pn/table.txt"
check "panel: stalled provider times out"          "timeout"         grep "^slow" "$pn/table.txt"
check "panel: failing provider reports error"      "error"           grep "^broken" "$pn/table.txt"
check "panel: error is retried once and then ok"   "attempts 2"      grep "^flaky" "$pn/table.txt"
check "panel: shared group runs one at a time"     "s1 s1 s2 s2"     sh -c "tr '\\n' ' ' < '$pn/trace' | sed 's/s2 s2 s1 s1/s1 s1 s2 s2/'"
check "panel: answer file written"                 "an answer"       cat "$pn/out/fine.out"
check "panel: status.json written"                 "timeout"         cat "$pn/out/status.json"
cat > "$pn/probe.toml" <<TOML
[[provider]]
name = "pongs"
cmd = ["sh", "-c", "echo PONG"]
[[provider]]
name = "mute"
cmd = ["sh", "-c", "echo hello"]
TOML
python3 "$P" run --prompt "$pn/prompt.md" --out "$pn/out2" --config "$pn/probe.toml" --probe > "$pn/table2.txt" 2>&1 || true
check "panel: --probe drops a provider that does not answer" "probe-failed" grep "^mute" "$pn/table2.txt"
check "panel: missing config -> message"           "no config found"  env -u PANEL_CONFIG HOME="$pn/nohome" python3 "$P" list --config "$pn/none.toml"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
