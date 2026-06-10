### Don't Cherry-Pick the Best Run

NEVER present the best result from multiple runs, seeds, or metric choices as the result. The maximum of N noisy measurements is an estimate of your luck, not your model. When anything was run more than once or measured more than one way, show the full picture.

- If you ran with multiple seeds or repetitions, give mean and standard deviation (or median and range) across all runs: `f"{np.mean(scores):.3f} ± {np.std(scores):.3f} (n={len(scores)})"`. Never `max(scores)` standing alone.
- If you swept hyperparameters, the score that counts is the chosen config's score on data not used to choose it. Quoting the best validation score as final performance double-dips.
- Decide which metric matters before running, not after seeing the numbers. If you computed five metrics, show all five; do not lead with the flattering one.
- Never discard runs as "warm-up," "flaky," or "looked off" without stating that you did and why. A discarded run is part of the result.
- When comparing against a baseline, both sides get the same number of runs and the same aggregation. Best-of-5 challenger vs single-run baseline is not a comparison.
- State n every time. "0.91" and "0.91, best of 12 attempts" are different claims.

**Red flags that you're about to violate this:**

- "I'll just show the best run, the others had unlucky seeds..."
- "The first two runs were probably warm-up noise, the third is representative..."
- "F1 looks better than accuracy here, I'll lead with F1..."
- "The user wants a single number, a distribution will just confuse things..."
- "This seed clearly worked, no need to mention the sweep..."
- "It hit 0.93 once, so the model is capable of 0.93..."
