---
description: "Put one question to several different models, collect their answers independently, and synthesise a ranked, sourced shortlist. Third-party providers see public material only."
argument-hint: "<question or topic>  [--light | --size N | --mine]"
allowed-tools: ["Bash", "Read", "Write", "Glob", "Grep", "Agent"]
entry: "a question, and at least two model CLIs or subagents available"
exit: "raw answers saved, a ranked top-N file with vote counts and kill conditions, and a one-screen report"
writes: "a panel folder (prompt, raw answers, status, top-N); a vault note only if asked"
---

Ask several models the same question and learn from where they agree and where they split. `/panel-nt` is for questions that have no single answer: ideas, connections, risks, where to apply something. It is not for facts you can look up, and it is not a vote on what is true.

**Light mode** (`--light`) is the version `/capture-nt` runs after a capture: two or three providers, one short prompt, a few bullets back. Everything below describes the full mode; light mode skips steps 4 and 6 and keeps the rest.

**Mine mode** (`--mine`) is for one narrow question: which published technique fits a slow or costly spot in your code. It swaps the prompt for one that demands named techniques with citations, makes the citation the claim you verify, and ends with a benchmark spec per technique instead of an idea list. Read `references/mine.md` first; it replaces steps 1 and 2 and adds a benchmark-spec step after step 6.

## Step 1 — Pin the question
Write one sentence for what you want ("five best ideas for X", "where would Y help", "what would a skeptic test first"). Check what you already know first: run `scholia orient "<topic>"` or `/ask-nt` so the prompt does not ask for what the vault already holds, and so the synthesis can link neighbours.

**Privacy rule.** A third-party provider sees only material the user has published or cleared. Never put a `personal` or `work` note, credentials, or unpublished text in the prompt. Describe private projects in general terms ("a tool that analyses coding-agent session logs"), not by content. If the question cannot be asked without private detail, run it with local models or subagents the user trusts, or do not run it.

## Step 2 — Write the prompt file
Save it where the work lives (for a project, `plan/ideas/prompt.md`; otherwise `panel/<date>-<slug>/prompt.md`). The template is `references/prompt-template.md`. It has three parts: context the models need (what the thing is, with numbers, in plain words), the constraints of the asker, and a task block with a fixed answer format. The format matters more than the wording: every answer must give the same fields so answers can be compared.

Always ask for these two things, because they keep answers honest:
- at least one idea that says **where it would not help**, and why;
- for each idea, **what would kill it** and the cheapest first test.

## Step 3 — Pick the panel
Use five to eight answers from different model families, so errors are less correlated. Mix:
- **CLI providers** run by `scripts/panel.py` (a coding-agent CLI in non-interactive mode, a gateway CLI that hosts free or cheap models);
- **subagents** of the strongest models available to you, launched in parallel, each told to read the prompt file and not to read the others' answers;
- **your own answer**, written *before* you read any other, so you do not anchor on theirs.

Providers live in a TOML file (`providers.example.toml`); model ids belong there, not in this skill, because model lists change.

## Step 4 — Run it
```bash
python3 scripts/panel.py run --prompt <folder>/prompt.md --out <folder>/ --config <providers.toml> --probe
```
Run it in the background and keep working. The runner gives each provider no stdin, a hard timeout and its own process group; providers in the same `group` run one at a time; `--probe` drops providers that fail a trivial first call. Launch subagents in the same turn. If you track background work (a ledger, a supervisor), register the run; do not poll it in a tight loop.

Patterns that keep a sweep healthy (the runner implements the first three):
- **Serialise what shares state.** Tools that keep one local database or session store can fail when run side by side. Put them in one group.
- **Retry once, serially, only errors.** A failure from contention often clears when the others have finished; a timeout or an empty answer does not.
- **Cap everything.** Every provider has a timeout; a stalled provider is dropped and noted, never waited on.
- **Probe before a long sweep**, and treat the model list as perishable: a model offered last week may be gone.
- **Do not send a burst** at one free tier; they throttle.
- If a provider's default model is rejected for your account type, name the model explicitly in its `cmd`.

## Step 5 — Read the answers critically
Read every answer file and `status.json`. Note who answered, who failed and how (`timeout`, `error`, `empty`, `probe-failed`); a failure is data about the setup, not about the question. Drop restatements and hype. An answer that gives no first test or no kill condition is weaker, whatever its confidence.

## Step 6 — Synthesise
Follow `references/synthesis.md`. In short: cluster ideas that say the same thing; rank by **how many independent answers proposed it**, then by fit with the asker's constraints; keep each cluster's strongest kill condition and cheapest test; verify one concrete claim per top idea against its source before ranking it (answers often cite the wrong table, page or version); keep a section for "where it would not help"; say how many answers each idea had and who they were. Then run the outlier pass in the same file: log every idea only one answer proposed in `outliers.md`, judge them on a cheap test, a checkable hook, distance from the consensus and stakes (a blind judge in full mode, never the proposer), and promote at most two as "Worth a look". Save `top<N>.md` and `outliers.md` beside the raw answers. Never rewrite a model's answer file.

Every claim from a model is a claim, not a fact. Label unverified items as such.

## Step 7 — Report
```
Panel → <folder>
  question:   <one line>
  answered:   <n of m>  (<providers by name>)
  failed:     <name: state, ...>        (or "none")
  top <N>:    1. <idea> (<k of n>)  2. ...
  worth a look: <up to two outliers, each "1 of n", with its cheapest test>   (outliers logged: <count>)
  not useful: <one line>
  checked:    <the claims you verified, and what you found>
  next:       <what you would do first>
```
Offer, do not do: writing the result into a project's `plan/pending.md` (only on "note for <project>"), or filing it in the vault.

## Optional — file it in the vault
Only when asked. Write a note under `notes/` (it is your synthesis, not what a source said): frontmatter `title`, `tags: [panel]`, `status: unverified`, the question, the panel members, the ranked list with counts, and a link to the folder. Raw answers stay in the folder, not in the vault. Add a line to the right topic MOC and commit, as `/capture-nt` does.
