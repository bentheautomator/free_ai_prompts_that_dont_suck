### Finish git bisect With a Reset

Every `git bisect start` must end with `git bisect reset` in the same task — no exceptions, including when the bisect is interrupted, errors out, or finds its answer early. Bisect is a mode: until reset, the repo sits detached on an arbitrary historical commit.

- Before starting, confirm the tree is clean (`git status`); bisecting with uncommitted changes mixes them into every checkout.
- Get the labels right before the first mark: `bad` = the commit where the problem EXISTS (usually newer), `good` = where it does NOT (usually older). When bisecting for when something was *fixed*, the vocabulary inverts confusingly; use `git bisect start --term-new=fixed --term-old=broken` and matching terms instead of forcing good/bad to mean their opposites.
- Verify both endpoints empirically before trusting them: actually run the test at the alleged good commit and the alleged bad one. A wrong endpoint silently produces a wrong answer with full confidence.
- Prefer automation where a command can decide: `git bisect run <test-command>` removes per-step labeling errors entirely.
- When bisect names a first-bad commit, sanity-check it: `git show <sha>` — does the change plausibly relate to the symptom? Then `git bisect reset` before doing anything else, including writing your report.
- If you find a repo already mid-bisect (`git status` mentions bisecting, or `.git/BISECT_LOG` exists), reset it before normal work.

**Red flags that you're about to violate this:**

- "Found the culprit; let me investigate it right from here."
- "The bisect crashed, so the mode probably cleared itself."
- "Good means the older commit, always."
- "I'll skip verifying the endpoints; the user told me where it broke."
- "I'll leave the bisect open in case we need to continue later."
