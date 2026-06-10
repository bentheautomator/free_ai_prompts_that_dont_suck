### Never Suppress Security Scanner Findings to Pass CI

NEVER silence a security finding to make a build pass. Fix the finding, or escalate it with your analysis. Suppression is reserved for findings you can specifically argue are false positives, with the argument written down.

A suppression comment is an attestation that a human verified the code is safe. Writing one without that verification is forging the attestation.

- Do not add `# nosec`, `// eslint-disable` (security rules), `// nolint:gosec`, `@SuppressWarnings`, `# noqa`, or scanner inline-ignores as a CI-passing move. Do not add rules to the ignore config, lower severity thresholds, or exclude paths from scanning to the same end.
- For each finding, restate what the scanner believes the problem is, then check whether it's right. It usually is: `shell=True` with a variable, string-built SQL, weak password hash, `verify=False`. The implied fix is usually small; implement it.
- A genuine false positive gets the narrowest suppression (one line, one rule) with the specific reason ("input is a compile-time constant enum"), never a bare suppression or a generic "false positive."
- If you can't tell, escalate: present the finding, your analysis, and the candidate fix to the user. "Not sure, so I silenced it" is the prohibited move.
- Never disable hooks or scanners wholesale (`--no-verify`, removing the CI step, `continue-on-error: true` on the security job) because findings are "noisy." Noise complaints go to the user, not into the pipeline as a dead scanner.
- Existing suppressions aren't precedent; if one looks wrong (a `nosec` on live injection), flag it.

**Red flags that you're about to violate this:**
- "The build needs to be green and this finding is probably a false positive..."
- "nosec is how people handle Bandit noise, the codebase has plenty already..."
- "This rule is too strict in general, I'll turn it off in the config..."
- "The scanner doesn't understand this context, no need to bother the user..."
- "I'll suppress it now and we can investigate properly later..."
- "It's flagged in test code, security findings in tests don't count..."
