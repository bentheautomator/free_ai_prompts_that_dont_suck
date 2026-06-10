---
title: Preserve Bug-for-Bug Compatibility
slug: preserve-bug-for-bug-compatibility
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: critical
one_liner: "Protects consumers that depend on old bugs before the bug gets fixed"
---

# Preserve Bug-for-Bug Compatibility

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from fixing a long-standing bug whose wrong behavior downstream consumers have built on, turning a correctness win into a breaking change.

**[Copy-paste ready version](../../install/preserve-bug-for-bug-compatibility.md)** — just the instruction block, no explanation.

## The Problem

A bug that has shipped for five years is not a bug anymore. It is behavior. Downstream consumers — internal services, customer scripts, partner integrations, spreadsheets in the finance department — have observed what the system actually does and built on it. They parse the misspelled JSON field. They compensate for the timestamp that's off by one hour. They rely on the list arriving in accidental-but-stable order. Hyrum's Law in its purest form: with enough users, every observable behavior of your system will be depended on by somebody, and the observable behavior includes the mistakes.

An AI assistant finds such a bug and fixes it, because fixing bugs is unambiguously good in its training signal. The fix is correct against the spec and catastrophic against reality: every consumer that adapted to the wrong behavior now breaks against the right one. And these breakages are uniquely nasty to debug, because the "cause" is a change that made the code more correct — the last place anyone looks.

The fix isn't necessarily wrong to want. It's wrong to do unilaterally, silently, as a side effect, without anyone deciding that breaking the adapted consumers is worth it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Bug-for-Bug Compatibility

NEVER unilaterally fix a long-standing bug in observable behavior. Wrong output that has shipped for years is depended on by consumers who adapted to it; correcting it is a breaking change, regardless of what the spec says.

Before fixing any bug in legacy behavior:

- Determine how long the wrong behavior has shipped. `git blame` the code; check changelog and release history. Days old: fix it. Years old: it has dependents until proven otherwise.
- Identify whether the behavior is observable outside the unit: API responses, file outputs, exported data, message payloads, ordering, formats, error codes and messages (yes, consumers parse error strings). Observable wrongness is the dangerous kind.
- Look for adaptation evidence: downstream code that re-corrects the value, comments like "API returns this off by one," test fixtures asserting the wrong value. Adaptation proves dependency.
- Report instead of fixing: "This is wrong per spec, but it's been shipping since 2017 and consumers may depend on it. Fix it, version it, or leave it?" That decision belongs to the user.
- If the fix proceeds, treat it like any breaking change: new versioned endpoint or flagged behavior where the codebase supports it, migration notice where it doesn't, and an explicit list of known consumers to check.

Internal-only, unobservable bugs (wrong intermediate value, corrected before any output) are exempt — fix those normally.

**Red flags that you're about to violate this:**
- "This is objectively a bug; fixing it can only make things better."
- "The spec clearly says the value should be X, not Y."
- "Anyone depending on broken behavior deserves what they get."
- "I'll fix this quietly since it's embarrassing it lasted this long."
- "It's a one-character fix, hardly even a change."
- "Consumers will be happy the output is finally correct."

---

## Why It Works

1. **It redefines the unit of correctness.** The AI evaluates code against specs; the instruction makes it evaluate change against deployed reality, where five-year-old wrong output is the de facto spec.
2. **Adaptation evidence is findable.** Downstream re-corrections and resigned comments are concrete artifacts to search for, converting "someone might depend on this" from paranoia into a checkable claim.
3. **It separates diagnosis from treatment.** The AI still gets to be right about the bug — in a report. Routing the fix decision to a human is what makes the breaking change deliberate instead of accidental.
4. **The exemption keeps the rule credible.** Unobservable internal bugs stay freely fixable, so the instruction reads as targeted compatibility discipline rather than blanket fix-aversion.

## Origin

A reporting API had returned percentages as fractions in a field documented as a percentage — 0.42 instead of 42 — since its first release. An assistant doing documentation-alignment work spotted the mismatch and fixed the code to match the docs. Every consumer that mattered had long since multiplied by 100 on their side; after the fix, dashboards across a dozen customer organizations showed conversion rates of 4,200%. The fix was reverted the same day, the docs were changed to match the bug, and the field is now wrong forever, on purpose, with a comment explaining exactly why.
