# Prompt template

```
Context A (the subject). <What it is, in plain words, with the numbers that matter. Public facts only.>

Context B (the asker). <What the asker builds or cares about, in general terms. What they already
rejected, so models do not repeat it. Constraints: hardware, time, no server, and so on.>

Task. Give your 5 BEST <ideas | connections | experiments>, ranked, best first. Include at least one
that says where it would NOT help, and why. For each give, in at most 5 short lines:
(a) name, (b) what is built or done and what the user sees, (c) why it beats the obvious
alternative, (d) the cheapest first build and what it needs, (e) the metric that decides it and what
could kill it, including the simplest standard fix that might give the same gain. Prefer work one
person can do in days. Be concrete and sceptical. No hype, no preamble.

Wildcard. After the five, add one more idea, labelled WILDCARD, that you expect the other answers to
miss. Give the same fields (a) to (e), and one sentence on why it is unusual. It may be a premise
challenge or a risk, not only a technique. If you have nothing, write WILDCARD: none.
```

Notes
- Keep Context A to what the models cannot guess. Put numbers in it; models anchor on them.
- Say what has been ruled out; otherwise every answer repeats it.
- Field (e) asks for the simple-fix rival because a headline gain often belongs to a plain fix the
  baseline lacked: an outside replication of TreeOPSD (arXiv:2610.23181) cut its +4.97-point lead
  over GRPO to +0.08 once the baseline got standard clipping. The synthesis should rank an idea lower
  when its answers name a plain rival nobody has measured against.
- A fixed format makes clustering possible. Do not let answers choose their own structure.
- The wildcard turns outliers into something deliberate: each is labelled and comes with the model's
  own reason, and the synthesis can treat them as a group (see `synthesis.md`, the outlier pass).
- Light mode: shorten Context B to one line and ask for four to six bullets, and drop the wildcard.
