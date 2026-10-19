# Synthesis rules

1. **Cluster.** Two ideas are the same when they would be built the same way and decided by the same
   metric, whatever they are called. Merge them and keep the best-specified version.
2. **Rank by independent support.** Count answers per cluster, and list who. A cluster proposed by
   all of them is a consensus, which is weak evidence of value but strong evidence of obviousness.
   A cluster proposed by one model, with a checkable first test, can still belong in the top N:
   say "1 of n" next to it.
3. **Keep the objections.** For each top idea keep the strongest kill condition any answer gave. A
   disagreement between answers (some propose, some say not to) goes in the file as a split, with
   both reasons.
4. **Verify one hook per top idea.** Pick the concrete claim the idea rests on (a table, a version, a
   number, whether a method exists) and check it against its source. Record "checked: found X".
   Answers often cite the wrong table or page, or a model that does not exist yet.
5. **Say the awkward thing.** If most answers say the premise is weak (for example, two things only
   share a word), put that at the top, before the list.
6. **Separate shortlist from raw.** `top<N>.md` names the sources and their settings; raw answers stay
   untouched beside it.
7. **No false precision.** Counts of answers are counts of answers; they are not probabilities.
8. **Keep the asker's decision visible.** End with the one decision the asker must make, and what you
   would do first.

## `top<N>.md` shape
```
# <question> — top N from <k> answers (<date>)
Sources: <who answered, how they were prompted, who failed and how>. Nothing here has been run.
## The point the answers agree on        (premise problems, if any)
## 1. <idea> — <k of n>                   (what, why, first build, decides, dies if)
...
## Where it would not help
## Also proposed
## Suggested first step
```
