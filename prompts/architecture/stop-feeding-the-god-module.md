---
title: Stop Feeding the God Module
slug: stop-feeding-the-god-module
category: architecture
tags: [universal, architecture, cohesion]
works_with: all
severity: high
one_liner: "Every new method landing in the one class that already does everything"
---

# Stop Feeding the God Module

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding yet another method to the 3,000-line class that already owns half the application.

**[Copy-paste ready version](../../install/stop-feeding-the-god-module.md)** — just the instruction block, no explanation.

## The Problem

Every codebase past a certain age has one: `UserService`, `AppManager`, `Helpers`, the class that started reasonable and now handles authentication, billing emails, CSV export, and a feature flag check. When an AI assistant needs a home for new logic, this class is the gravitational center — it's already imported everywhere, it already has the dependencies wired, and grep shows that everything else lives there too. So the new method lands there. Method 147.

The mechanism is self-reinforcing. The god module is the path of least resistance precisely because it's a god module: maximum existing access, minimum new wiring. Each addition makes the next addition more likely, makes the class harder to test (its test file needs every mock in the project), and widens the blast radius of every change to it. AI assistants accelerate this because they optimize for "where does this fit with the least friction," and the god module is always the answer to that question.

Nobody decides to build a god module. It's built one perfectly reasonable method at a time, mostly by whoever — or whatever — wasn't told to stop.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stop Feeding the God Module

NEVER add new responsibilities to a class or module that is already the largest in its area and already spans multiple unrelated concerns. The fact that everything else lives there is the symptom, not the precedent.

God modules grow one reasonable-looking method at a time, and every addition raises the cost of testing, reviewing, and eventually splitting them.

- Before adding a method to a class, check its size and scan its existing public surface; if it already covers several unrelated domains (auth + export + notifications, say), your method goes somewhere else
- Put the new logic in a small, focused module named for what it does (`InvoiceExporter`, `session_renewal.py`), even if that means creating a file; have the god module delegate to it if callers expect the old entry point
- Do not justify placement with "the dependencies are already injected here"; wire the two dependencies your new code actually needs into its new home
- You are not required to refactor the god module — that's a separate task needing explicit approval — but you are required to stop enlarging it
- If genuinely everything in the codebase routes through this class and there is no other viable seam, say so in your summary instead of silently adding method 148

**Red flags that you're about to violate this:**
- "All the related logic is already in this class..."
- "It already has the database client injected, so it's the easiest place..."
- "One more method on a big class doesn't change anything..."
- "Creating a new file for one function feels like overkill..."
- "I'll add it here now and someone can move it during the big refactor..."

---

## Why It Works

1. **It breaks the gravity loop.** God modules grow because each addition lowers the friction for the next; a hard stop on new responsibilities is the only intervention that works without a refactor.

2. **It separates stopping from fixing.** The AI can't use "refactoring is out of scope" as cover, because the rule only demands the cheap half: put new code elsewhere and delegate.

3. **It reprices the wiring excuse.** "Dependencies are already here" is the honest reason god modules win; requiring fresh wiring for the two real dependencies exposes how small the actual cost is.

4. **It forces a named decision.** When there truly is no other seam, surfacing that in the summary turns a silent default into a reviewable architectural choice.

## Origin

A team's `OrderManager` hit 4,200 lines, and a postmortem traced the final 1,500 to a six-month window of AI-assisted changes — each one a single sensible method, each one citing the previous ones as the pattern. The class's test suite took eleven minutes and required mocking nineteen collaborators, so engineers had quietly stopped writing tests for it. The incident that triggered the postmortem was a refund bug hiding in a method that handled both refunds and loyalty points, because by then everything did two things.
