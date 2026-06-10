---
title: No Upward Imports From Lower Layers
slug: no-upward-imports-from-lower-layers
category: architecture
tags: [universal, architecture, layering]
works_with: all
severity: high
one_liner: "Core or data layers importing from the app or UI layers above them"
---

# No Upward Imports From Lower Layers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from making a low-level module (core, data, shared, utils) import anything from the application or UI layers above it.

**[Copy-paste ready version](../../install/no-upward-imports-from-lower-layers.md)** — just the instruction block, no explanation.

## The Problem

The AI is writing a function in the data layer and needs a constant, an error class, or a formatting helper. It searches the codebase, finds the symbol in an application-layer file, and imports it. The arrow now points up: the foundation depends on the roof. This is how `core/validation.py` ends up importing from `api/routes/users.py` for one error message string.

Upward imports are uniquely corrosive because lower layers are the most-imported code in the system. The moment `shared/` imports from `features/checkout/`, everything that imports `shared/` transitively depends on checkout — its framework, its config, its startup cost. Unit tests for a pure utility suddenly need application context to run. Extracting the core into a library becomes impossible. And the import graph starts sprouting cycles, because the upper layer already imported the lower one.

AI assistants do this because search results carry no layer information. The symbol exists, the import resolves, the tests pass. Which direction the dependency arrow points is precisely the thing nothing on the screen tells them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Upward Imports From Lower Layers

NEVER import from a higher layer while editing a lower one. Dependencies point in one direction only: UI imports application, application imports domain, domain imports shared/core. The reverse direction is forbidden at every step.

A lower layer that imports upward drags the entire upper layer into everything that depends on the lower one, and it is the standard first step toward an import cycle.

- Before importing a symbol, note which layer it lives in; if it is above the file you are editing, do not import it
- If a lower layer needs a constant, type, or helper that currently lives above it, MOVE that symbol down to the lower layer (updating the original call sites), or duplicate a trivial constant; never reach up for it
- If a lower layer needs to trigger upper-layer behavior (send a notification, invalidate a UI cache), expose a hook: emit an event, accept a callback, or define an interface the upper layer implements and injects
- Shared/util/core modules are the bottom; they import only the standard library, third-party packages, and each other, never feature or app code
- If you cannot tell which layer a module belongs to, check what the project's existing files in that directory import and match the direction

**Red flags that you're about to violate this:**
- "The error class I need is defined in the API layer, I'll import it from there..."
- "It's just a constant, the direction of the import doesn't matter..."
- "Moving the symbol down means editing files outside my task..."
- "The util can call the notification service directly, it's only one call..."
- "Search found it in features/, but an import is an import..."

---

## Why It Works

1. **It makes direction a checked property.** "Note which layer it lives in" inserts an explicit step where the AI previously had none; the import either points down or it doesn't happen.

2. **It legitimizes moving symbols down.** The honest fix often means touching the original definition site, which the AI avoids as scope expansion; the rule explicitly authorizes it so the shortcut loses its excuse.

3. **It provides the inversion toolkit.** Events, callbacks, and injected interfaces are the standard answers to "but the lower layer genuinely needs the upper one"; listing them keeps the AI from concluding the upward import was necessary.

4. **It anchors the bottom of the stack.** Declaring what shared/core may import leaves no ambiguity for the most-imported, most-damaging place to get this wrong.

## Origin

A shared date-formatting module needed a locale default, and an assistant imported it from the web app's settings module rather than moving the constant down. The shared module was also used by a billing cron job, which now pulled in the web framework at import time; the job's container image grew, its cold start tripled, and a later web-config refactor broke nightly invoicing. The fix was moving one constant, exactly what the rule would have required up front.
