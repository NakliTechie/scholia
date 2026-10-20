#!/usr/bin/env python3
"""Fuzz the skip-rebuild check against a full rebuild.

    python3 tests/fresh_fuzz.py VAULT_COPY [--runs 200] [--seed 1]

VAULT_COPY must be a throwaway copy of a vault (it is edited in place). Each run
applies one random change (append a line, same-size in-place edit, add, delete,
rename, touch every file, or nothing), runs `scholia stats` (which may skip the
rebuild), dumps every table, runs `scholia build` (always a full rebuild), dumps
again, and fails if the two dumps differ. A stale index shows up as a diff.
Exit 0 = no difference in any run.
"""
import argparse
import os
import random
import sqlite3
import subprocess
import sys
from pathlib import Path

SCHOLIA = Path(__file__).resolve().parent.parent / "bin" / "scholia"
TABLES = ("notes", "tags", "links", "fraglinks", "urls", "linkstyle")


def run(vault, *args):
    subprocess.run([sys.executable, str(SCHOLIA), "--vault", str(vault), *args],
                   check=True, capture_output=True)


def dump(vault):
    db = sqlite3.connect(vault / ".scholia.db")
    out = {t: sorted(db.execute(f"SELECT * FROM {t}").fetchall(), key=repr)
           for t in TABLES}
    # FTS content: the ranked result of a fixed set of queries
    for q in ("model", "licence", "agent", "benchmark"):
        out["fts:" + q] = db.execute(
            "SELECT rowid FROM notes_fts WHERE notes_fts MATCH ? "
            "ORDER BY rank, rowid", (q,)).fetchall()
    db.close()
    return out


def files(vault):
    return sorted(p for d in ("sources", "notes", "topics")
                  for p in (vault / d).glob("*.md"))


def change(vault, rng, n):
    kind = rng.choice(("append", "samesize", "restoremtime", "add", "delete",
                       "rename", "touchall", "nothing"))
    fs = files(vault)
    if kind == "append":
        with rng.choice(fs).open("a") as f:
            f.write(f"\nfuzz line {n} [[some-slug]]\n")
    elif kind == "samesize":
        p = rng.choice(fs)
        text = p.read_text(encoding="utf-8", errors="replace")
        i = text.find("e", len(text) // 2)
        if i >= 0:
            p.write_text(text[:i] + "E" + text[i + 1:], encoding="utf-8")
    elif kind == "restoremtime":
        # a same-size edit that puts the old modification time back
        p = rng.choice(fs)
        st = p.stat()
        text = p.read_text(encoding="utf-8", errors="replace")
        i = text.find("a", len(text) // 2)
        if i >= 0:
            p.write_text(text[:i] + "A" + text[i + 1:], encoding="utf-8")
            os.utime(p, ns=(st.st_atime_ns, st.st_mtime_ns))
    elif kind == "add":
        (vault / "notes" / f"fuzz-{n}.md").write_text(
            f'---\ntitle: "Fuzz {n}"\ntags: [fuzz]\n---\nbody {n} model\n')
    elif kind == "delete" and len(fs) > 10:
        rng.choice(fs).unlink()
    elif kind == "rename" and len(fs) > 10:
        p = rng.choice(fs)
        p.rename(p.with_name(f"renamed-{n}.md"))
    elif kind == "touchall":
        for p in fs:
            os.utime(p)
    return kind


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vault", type=Path)
    ap.add_argument("--runs", type=int, default=200)
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args()
    rng = random.Random(args.seed)
    run(args.vault, "build")
    bad = 0
    for n in range(1, args.runs + 1):
        kind = change(args.vault, rng, n)
        run(args.vault, "stats")            # may skip the rebuild
        got = dump(args.vault)
        run(args.vault, "build")            # full rebuild, the reference
        want = dump(args.vault)
        if got != want:
            bad += 1
            diff = [t for t in want if got[t] != want[t]]
            print(f"DIFF run {n} after {kind}: {diff}")
        if rng.random() < 0.5:              # sometimes let the racy window pass
            import time
            time.sleep(2.1)
    print(f"{args.runs} runs, {bad} with a difference")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
