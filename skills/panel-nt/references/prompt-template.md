# Prompt template

```
Context A (the subject). <What it is, in plain words, with the numbers that matter. Public facts only.>

Context B (the asker). <What the asker builds or cares about, in general terms. What they already
rejected, so models do not repeat it. Constraints: hardware, time, no server, and so on.>

Task. Give your 5 BEST <ideas | connections | experiments>, ranked, best first. Include at least one
that says where it would NOT help, and why. For each give, in at most 5 short lines:
(a) name, (b) what is built or done and what the user sees, (c) why it beats the obvious
alternative, (d) the cheapest first build and what it needs, (e) the metric that decides it and what
could kill it. Prefer work one person can do in days. Be concrete and sceptical. No hype, no preamble.
```

Notes
- Keep Context A to what the models cannot guess. Put numbers in it; models anchor on them.
- Say what has been ruled out; otherwise every answer repeats it.
- A fixed format makes clustering possible. Do not let answers choose their own structure.
- Light mode: shorten Context B to one line and ask for four to six bullets.
