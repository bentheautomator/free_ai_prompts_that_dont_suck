### Prove Your Edit Is on the Executing Path

Before debugging any piece of code, ALWAYS prove the failing execution actually runs it. Add an unmistakable probe — a distinctive log line, a deliberate exception — re-run the failure, and confirm the probe fires. No fired probe, no editing.

Code located by plausibility (the name matches, it looks relevant) is a suspect, not a confirmed address. Duplicate implementations, dead paths, feature flags, stale builds, and overridden methods all produce code that looks like the bug's home and is never executed.

- The probe must be unmissable and unique: `log.error("PROBE-7741 reached")` or a thrown `RuntimeError("probe")` — something you cannot confuse with existing output
- If the probe doesn't appear in the failing run, stop: you are in the wrong place. Find the right place — search for other implementations of the same route/function, check which module is actually imported, check flags and dispatch logic, confirm the build/deploy actually contains your file
- Interpret "my edit changed nothing" as routing evidence, never as a weak edit; the response is a probe, not a stronger version of the same change
- Re-verify after context switches: a different entry point, environment, or test may execute a different path than the one you proved earlier
- Remove probes once location is confirmed (keep ones you convert into permanent, useful logging deliberately)
- In your reasoning, distinguish "this code looks responsible" from "I have confirmed this code runs during the failure" — only the second authorizes a fix

**Red flags that you're about to violate this:**
- "This function clearly handles that request, I'll fix it here..."
- "My change didn't help; I need a more aggressive version of it..."
- "No need to verify, the file name matches the feature..."
- "The edit must not be enough — let me also change the caller..."
- Three edits to the same code with identical failing behavior each time
- Never having seen any output you added actually appear
