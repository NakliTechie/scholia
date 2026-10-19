#!/usr/bin/env python3
"""panel: send one prompt to several model CLIs and collect their answers.

Python 3.11, standard library only. It launches each provider as a subprocess with
no stdin, a hard timeout and its own process group, writes one answer file per
provider, and records a status for each. Providers that share local state go in the
same group and run one at a time; providers in different groups run together.

    panel.py run  --prompt prompt.md --out answers/ [--config panel.toml] [--probe]
    panel.py list [--config panel.toml]

Config (TOML), one [[provider]] table each:

    [defaults]
    timeout = 240          # seconds per provider
    probe_timeout = 60
    retry = 1              # one serial retry for providers that errored

    [[provider]]
    name  = "cli-a-model-x"
    cmd   = ["some-cli", "run", "--model", "{model}", "{prompt}"]
    model = "model-x"
    group = "cli-a"        # same group = one at a time; default: its own group

In `cmd`, {prompt} is the prompt text, {prompt_file} its path, {model} the model.
Exit status: 0 if at least one provider answered, 1 if none did, 2 on usage errors.
"""
from __future__ import annotations

import argparse
import json
import os
import signal
import subprocess
import sys
import threading
import time
import tomllib
from pathlib import Path

PROBE_PROMPT = "Reply with exactly: PONG"


def find_config(arg: str | None) -> Path:
    if arg:
        if not Path(arg).expanduser().is_file():
            sys.exit(f"panel: no config found at {arg}")
        return Path(arg).expanduser()
    cands = [os.environ.get("PANEL_CONFIG"), "panel.toml",
             str(Path.home() / ".config" / "panel-nt" / "providers.toml")]
    for c in cands:
        if c and Path(c).expanduser().is_file():
            return Path(c).expanduser()
    sys.exit("panel: no config found (use --config, $PANEL_CONFIG, ./panel.toml "
             "or ~/.config/panel-nt/providers.toml)")


def load(path: Path) -> tuple[dict, list[dict]]:
    data = tomllib.loads(path.read_text())
    d = {"timeout": 240, "probe_timeout": 60, "retry": 1, **data.get("defaults", {})}
    provs = []
    for i, p in enumerate(data.get("provider", [])):
        if "name" not in p or "cmd" not in p:
            sys.exit(f"panel: provider #{i + 1} needs name and cmd")
        provs.append({"model": "", "group": p["name"], "timeout": d["timeout"], **p})
    if not provs:
        sys.exit("panel: no [[provider]] tables in config")
    return d, provs


def argv_for(p: dict, prompt: str, prompt_file: str) -> list[str]:
    out = []
    for a in p["cmd"]:
        out.append(a.replace("{prompt_file}", prompt_file)
                    .replace("{prompt}", prompt)
                    .replace("{model}", p["model"]))
    return out


def run_one(p: dict, prompt: str, prompt_file: str, timeout: float) -> dict:
    t0 = time.time()
    try:
        proc = subprocess.Popen(argv_for(p, prompt, prompt_file), stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                                start_new_session=True)
    except OSError as e:
        return {"state": "error", "seconds": 0.0, "rc": None, "out": "", "err": str(e)}
    try:
        out, err = proc.communicate(timeout=timeout)
        state = "ok" if proc.returncode == 0 and out.strip() else (
            "empty" if proc.returncode == 0 else "error")
        return {"state": state, "seconds": round(time.time() - t0, 1), "rc": proc.returncode,
                "out": out, "err": err[-400:]}
    except subprocess.TimeoutExpired:
        for sig in (signal.SIGTERM, signal.SIGKILL):
            try:
                os.killpg(proc.pid, sig)
            except ProcessLookupError:
                break
            try:
                proc.wait(timeout=3)
                break
            except subprocess.TimeoutExpired:
                continue
        return {"state": "timeout", "seconds": round(time.time() - t0, 1), "rc": None,
                "out": "", "err": ""}


def by_group(provs: list[dict]) -> dict[str, list[dict]]:
    g: dict[str, list[dict]] = {}
    for p in provs:
        g.setdefault(p["group"], []).append(p)
    return g


def sweep(provs: list[dict], work) -> None:
    """Run work(p) for each provider: groups concurrently, members of a group in turn."""
    threads = []
    for members in by_group(provs).values():
        def go(ms=members):
            for p in ms:
                work(p)
        t = threading.Thread(target=go)
        t.start()
        threads.append(t)
    for t in threads:
        t.join()


def cmd_run(a) -> int:
    d, provs = load(find_config(a.config))
    if a.only:
        want = set(a.only.split(","))
        provs = [p for p in provs if p["name"] in want]
        if not provs:
            sys.exit("panel: --only matched no provider")
    prompt_file = Path(a.prompt).resolve()
    prompt = prompt_file.read_text()
    out_dir = Path(a.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    status: dict[str, dict] = {}
    lock = threading.Lock()

    live = provs
    if a.probe:
        dropped = {}
        def probe(p):
            r = run_one(p, PROBE_PROMPT, str(prompt_file), d["probe_timeout"])
            if "pong" not in r["out"].lower():
                with lock:
                    dropped[p["name"]] = {"state": "probe-failed:" + r["state"], "seconds": r["seconds"],
                                          "attempts": 0, "bytes": 0}
        sweep(provs, probe)
        status.update(dropped)
        live = [p for p in provs if p["name"] not in dropped]

    def work(p, attempt=1):
        r = run_one(p, prompt, str(prompt_file), p["timeout"])
        if r["out"].strip():
            (out_dir / f"{p['name']}.out").write_text(r["out"])
        with lock:
            status[p["name"]] = {"state": r["state"], "seconds": r["seconds"], "attempts": attempt,
                                 "bytes": len(r["out"].encode()), "stderr_tail": r["err"].strip()[-200:]}

    sweep(live, work)
    # One serial retry for providers that errored (often contention between runs).
    # Timeouts and empty answers are not retried.
    for _ in range(int(d["retry"])):
        again = [p for p in live if status[p["name"]]["state"] == "error"]
        for p in again:
            work(p, status[p["name"]]["attempts"] + 1)

    (out_dir / "status.json").write_text(json.dumps(status, indent=2))
    width = max(len(n) for n in status)
    for name in sorted(status):
        s = status[name]
        print(f"{name:<{width}}  {s['state']:<22} {s['seconds']:>6}s  {s['bytes']:>6} B  attempts {s['attempts']}")
    ok = sum(1 for s in status.values() if s["state"] == "ok")
    print(f"{ok} of {len(status)} answered")
    return 0 if ok else 1


def cmd_list(a) -> int:
    d, provs = load(find_config(a.config))
    for p in provs:
        print(f"{p['name']}  group={p['group']}  timeout={p['timeout']}  model={p['model'] or '-'}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(prog="panel")
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--prompt", required=True)
    r.add_argument("--out", required=True)
    r.add_argument("--config")
    r.add_argument("--only", help="comma-separated provider names")
    r.add_argument("--probe", action="store_true", help="drop providers that fail a trivial first call")
    r.set_defaults(fn=cmd_run)
    l = sub.add_parser("list")
    l.add_argument("--config")
    l.set_defaults(fn=cmd_list)
    a = ap.parse_args()
    return a.fn(a)


if __name__ == "__main__":
    sys.exit(main())
