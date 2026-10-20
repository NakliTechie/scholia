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
9. **Log every outlier, and judge them separately.** An outlier is a cluster proposed by one answer
   (or by at most a fifth of the panel). Never drop one. Write them all to `outliers.md` and promote
   at most two to the shortlist as "Worth a look". See the outlier pass below.

## The outlier pass

Consensus measures obviousness, not value, and a lone voice is not evidence of value: singletons are
also where hallucinations live. An outlier earns a slot only by carrying its own evidence.

1. **List.** After clustering, write every singleton with who proposed it, its stated hook, its first
   test and its kill condition, close to the answer's own words. Add the wildcards the prompt asked
   for (the idea each model expected the others to miss) with the model's own reason. Record how each
   was merged or left alone, so a mistaken merge can be found later.
2. **Check one hook each.** Same rule as for the top ideas (rule 4). Cap at about five outliers; take
   the wildcards first, then the cheapest tests.
3. **Judge on four checks, 0 to 2 each:**
   - *Hook*: the claim or citation it rests on exists and says what is claimed.
   - *Cheap test*: a first test of about a day or one command. A low-probability idea with a one-command
     test is worth a slot.
   - *Distance*: not a restatement or variant of a consensus idea; it attacks a different cost or
     premise. Where an embedding index exists (`scholia semantic`), the distance to the nearest
     consensus cluster is a number; otherwise say how you judged it.
   - *Stakes*: it names a failure or risk the consensus ignores. Some outliers matter because they
     protect (a missing lock, a wrong premise).
4. **Who judges.** Never the proposer. Not the synthesizer alone, because it anchors on the consensus
   and on its own answer, which was written first. In full mode use a blind judge: a fresh agent,
   ideally of another family, sees the question, the asker's constraints and the outliers shuffled,
   with no author names and no vote counts, and scores the four checks and writes the strongest
   objection to each. For the survivors, send each to two panelists who did not propose it: "what is
   the cheapest way to refute this?" An outlier that survives, or that changes an objector's mind, is
   promoted. In light mode the synthesizer applies the four checks alone and says so.
5. **Run the one-command tests before promoting.** If an outlier's first test is a single command or a
   few lines against a scratch copy, run it. A measurement settles an outlier at once and beats any
   judge: in a trial, the judge's second pick for promotion measured no gain, while a lower-scored
   outlier exposed a real hole in the code the panel had just inspired. Record the result and set the
   status (`tested`, `useful` or `dead`).
6. **Promote at most two** as "Worth a look (1 of n, unconfirmed by others)", each with its test and
   kill condition, preferring outliers that are still open after step 5. The five consensus ideas stay
   the headline. The asker decides.
7. **Keep a ledger.** Each outlier carries a status in `outliers.md`: `open`, `tested`, `useful` or
   `dead`. Update it when a later run or test settles it. Over runs this gives each model's hit rate on
   outliers, which is the one judge that does not need an opinion.

Watch for a judge that favours fluent or long outliers: the four checks reward what is checkable and
cheap. Judging with a model of the same family as the proposer biases toward it.

## `top<N>.md` shape
```
# <question> — top N from <k> answers (<date>)
Sources: <who answered, how they were prompted, who failed and how>. Nothing here has been run.
## The point the answers agree on        (premise problems, if any)
## 1. <idea> — <k of n>                   (what, why, first build, decides, dies if)
...
## Where it would not help
## Worth a look (1 of n)                  (at most two promoted outliers, each with test and kill condition)
## Also proposed                          (one line per remaining outlier; the full log is outliers.md)
## Suggested first step
```

## `outliers.md` shape
```
# Outliers — <question> (<date>)
| # | idea | proposed by | wildcard? | hook checked | cheap test | distance | stakes | judge total | status |
Then, per outlier: what it is (close to the answer's words), its first test, its kill condition, the
strongest objection (blind judge or cross-examiner), and what happened to it (merged into which
cluster, promoted, left in the log).
```
