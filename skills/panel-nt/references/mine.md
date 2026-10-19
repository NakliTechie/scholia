# Mine mode: known techniques for a slow or costly spot in your code

Use this when the question is "what published technique fits this bottleneck?", not "what ideas do you have?". A model recalls named algorithms well. It recalls them best when the problem is stated as a data structure with sizes, not as a vague wish. The pattern: state the bottleneck exactly, ask several models for named techniques that match its structure, check the citations, then write the benchmark that would decide each one before any code exists.

## When it fits
- A hot path, a slow command, a large memory cost, a worst case that dominates the average.
- You can run the current code and get a number.
- Not for "make it better": with no number there is nothing to decide a technique by.

## Step M1 — State the bottleneck
Write these five lines in the prompt file. Without all five, do not run the panel.
1. **The structure.** What the data is (a graph, a sorted list, a decision diagram, a matrix of this shape), in words a stranger would understand.
2. **The operation.** What is repeated, and what is expensive about it.
3. **The numbers.** Input sizes, the current time or memory, and where the worst case comes from. One measured number beats three adjectives. Give the split by phase (a profile, even a rough one), and state any fact that bounds a gain, such as "all inserts already run in one transaction". Without it, answers cite a famous speed-up that your code already has.
4. **The constraint.** Language, no new dependencies, must stay exact or may approximate, must keep the output format.
5. **Already tried or ruled out.** So answers do not repeat it.

Privacy rule from `SKILL.md` still applies: describe the structure and the operation, never paste private source. Public code can be linked.

## Step M2 — The prompt
Use the template below instead of `prompt-template.md`. Ask for **named** techniques so each can be checked.

```
Context. <the five lines from M1>

Task. Name the 5 published techniques (an algorithm, a data structure, or a paper) most likely to
make this operation faster or smaller, best first. Include one that would NOT help and why.
For each give, in at most 6 short lines:
(a) the technique's standard name and one citation (author, title or venue, year),
(b) why it fits THIS structure, in one sentence about the structure, not about the technique,
(c) what the cost is now versus what the technique claims (complexity, or a published number),
(d) the smallest change that tries it (what to replace, roughly how many lines),
(e) the benchmark that decides it: the input, the baseline, and the number that counts as a win,
    plus the input where it would lose.
Mark every number as published (with where) or estimated by you. No hype. If you are not sure the technique exists under that name, say so.
```

## Step M3 — Run and synthesise
Run steps 3 to 6 of `SKILL.md` unchanged (panel, run, read critically, cluster). Two changes:
- **Cluster by technique, not by wording.** "Memoised cover extraction" and "ISOP recurrence" may be one idea; check before merging.
- **Rank the obvious and the surprising separately.** When every answer proposes the same technique, that is consensus: it says the profile already pointed there. List techniques proposed by one or two answers with a checkable citation in their own group; they are where a panel adds something.
- **The hook to verify is the citation.** For every top technique, confirm the named source exists and says what the answer claims (the complexity, the table). Drop a technique whose citation cannot be found. Check the specific claim (a quoted sentence, a table, a number), not only that the title exists: answers misquote real documents, and attach a real paper to a different mechanism than the one it describes (a build-systems paper's content-hash traces named as if they were modification-time checks). Also check the code-level premise each top technique relies on ("your inserts are not batched") against your own source before writing its spec. For depth, hand the top two or three to a citation-checked research run if you have one.

Mine prompts are long and ask for citations, so the slowest providers take several minutes; allow at least 300 s for a coding-agent CLI and expect one or two providers to time out or hit an upstream overload.

## Step M4 — Benchmark spec before code
For each surviving technique, write a spec, not an implementation:
- the baseline commit and the command that measures it;
- the inputs: the typical case, the worst case from M1, and the case where the technique should lose;
- the table to fill: operation, baseline, candidate, speedup, in the same unit;
- the win condition, stated before any run (for example "at least 5x on the worst case and no more than 5% slower on the typical case");
- the correctness check (same output, or a stated tolerance).
Save these beside `top<N>.md`. The decision is the owner's; the panel supplies candidates and the spec.

## What the result is, and is not
A ranked list of named techniques with checked citations and a benchmark spec for each. It is not evidence that any of them works on your code. A recalled technique that fits the structure on paper often loses on the typical case; the "where it would lose" input in M4 is there for that.
