---
title: Add the Button, Not a Design System
slug: add-the-button-not-a-design-system
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI turning a one-button request into a component library refactor"
---

# Add the Button, Not a Design System

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from answering a small UI request with new shared components, theme tokens, and refactors of existing screens.

**[Copy-paste ready version](../../install/add-the-button-not-a-design-system.md)** — just the instruction block, no explanation.

## The Problem

"Add an Export button next to the search bar." A reasonable response is fifteen lines in one component. What the AI often ships instead: a new `Button` primitive with `variant`, `size`, and `icon` props, a colors-and-spacing tokens file, and a refactor of the twelve existing buttons across the app to use the new primitive — plus, somewhere in there, the Export button. The request touched one screen. The diff touches nine.

The escalation logic is easy to reconstruct: the AI sees inline styles and duplicated button markup, diagnoses the absence of a component system, and decides the "right" way to add one button is to first build the system it would belong to. But each refactored existing button is a regression risk on a screen the task had no business touching, and visual regressions are exactly the kind QA doesn't catch without pixel diffing. Meanwhile the actual deliverable — one button — is now blocked on review of an unrequested architecture change.

Design systems are real projects with real owners, naming debates, and accessibility audits. They don't get built as a side effect of a button ticket, and an AI shouldn't start one on its own authority.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Add the Button, Not a Design System

When asked to add or change one UI element, change only that element on only the screens named. NEVER create shared components, theme tokens, or style abstractions as part of the task, and never restyle existing elements to match.

The core problem: "doing it right" by building reusable UI infrastructure turns a one-screen change into a multi-screen regression risk and blocks the small deliverable behind a large unrequested one.

- Build the element in place, following whatever pattern its immediate neighbors use, even if that pattern is duplication or inline styles
- Do not extract a new shared component unless extraction was the request
- Do not add or reorganize theme files, token files, or global styles
- Do not update other instances of similar elements "for consistency"; consistency passes are their own task with their own review
- Matching the existing look by copying nearby styles is correct here; deduplicating those styles is not
- If the codebase clearly needs a shared primitive, ship the requested element first, then propose the extraction in a sentence or two

**Red flags that you're about to violate this:**
- "There's no Button component, so I'll create one properly first..."
- "These styles are duplicated everywhere, perfect time to centralize..."
- "I'll update the other buttons too so the UI stays consistent..."
- "Hardcoded colors should really be theme tokens..."
- "Future buttons will be much easier after this small refactor..."
- "Doing it the quick way would just add to the mess..."

---

## Why It Works

1. **It legitimizes the "worse" local pattern.** The AI resists copying duplicated styles because duplication reads as a defect; explicitly blessing it for this task removes the justification for the refactor.

2. **It separates consistency work from feature work.** "For consistency" is the strongest-sounding escalation excuse; naming consistency passes as a distinct task with distinct review denies it.

3. **It scopes by screen, not by concept.** "One element on the screens named" is checkable; "appropriate UI change" is not, and the AI exploits unbounded definitions.

4. **It reorders deliverables.** Requiring the requested element to ship before any proposal means the user gets their button even if they decline the system.

## Origin

A startup asked an assistant to add a "Copy link" button to a share dialog. It came back with a new component library folder, three primitives, a theme provider wrapped around the app root, and rewrites of four screens. The theme provider changed font inheritance subtly enough that nobody noticed until a customer screenshot showed the pricing page rendering in fallback serif. The share dialog change itself was eleven lines, and shipped a week later than it should have.
