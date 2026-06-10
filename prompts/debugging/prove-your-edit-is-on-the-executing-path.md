---
title: Prove Your Edit Is on the Executing Path
slug: prove-your-edit-is-on-the-executing-path
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI editing code the failing process never actually runs"
---

# Prove Your Edit Is on the Executing Path

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from repeatedly "fixing" code that the failing execution never reaches.

**[Copy-paste ready version](../../install/prove-your-edit-is-on-the-executing-path.md)** — just the instruction block, no explanation.

## The Problem

The AI finds a function whose name matches the broken feature, edits it, re-runs, sees no change in behavior — and concludes the fix needs to be *stronger*, editing the same function harder. Three rounds later, someone notices the function is one of two implementations and the failing request is served by the other one. Or the edit was in `src/` while the process runs from `dist/`. Or the handler is registered behind a feature flag that's off. Or there are two installed copies of the package, or the method is overridden in a subclass, or the dead code path was abandoned a year ago and just never deleted.

"My change had no effect" is one of the most informative observations in debugging — it almost always means the change isn't on the executing path — but AI assistants reliably misread it as "the change was insufficient." The misreading happens because the AI located the code by *plausibility* (name matches, looks relevant) rather than by *evidence of execution*, and plausibility doesn't distinguish the live implementation from its dead twin.

The tax is brutal: entire sessions spent strengthening edits in a file the program never loads, theories growing more exotic to explain the unresponsiveness, while a one-line probe would have settled the question in the first minute.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It corrects the key misreading.** "No effect = wrong location" versus "no effect = weak fix" is the fork where these sessions go wrong; hardcoding the first interpretation stops the strengthening spiral at round one.

2. **It separates plausibility from execution.** The AI finds code by textual relevance, which is exactly the signal that duplicate and dead implementations fake perfectly; the probe is the only evidence class they can't fake.

3. **It makes the check nearly free.** One log line and one re-run settle code location for good; the instruction's cost-benefit is so lopsided that skipping it loses its main excuse (overhead).

4. **It lists the real-world routing traps.** Flags, dual implementations, stale dist/, subclass overrides — naming them turns "probe didn't fire" from a dead end into a checklist of where to look next.

## Origin

An assistant spent a session fixing date parsing in a checkout validation function — four increasingly thorough rewrites of the validation logic, zero change in the failing behavior. The function was the v1 validator; checkout had been routed through a v2 module for over a year, and the v1 file survived only because nobody had deleted it. A probe exception in round one would have shown the file was never loaded. Instead, the v1 validator ended the day enormously improved, and the actual bug — two lines in v2 — was found by whoever asked "wait, is this code even called?"
