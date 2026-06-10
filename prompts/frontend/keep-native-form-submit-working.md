---
title: Keep Native Form Submit Working
slug: keep-native-form-submit-working
category: frontend
tags: [universal, frontend]
works_with: all
severity: high
one_liner: "Stops onClick-only forms that break Enter-to-submit and native validation"
---

# Keep Native Form Submit Working

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from building forms as loose inputs plus an onClick button, which kills Enter-to-submit, native validation, and password-manager integration.

**[Copy-paste ready version](../../install/keep-native-form-submit-working.md)** — just the instruction block, no explanation.

## The Problem

A login form from an AI assistant frequently arrives as a `<div>` holding two inputs and `<button onClick={handleLogin}>`. It submits when clicked, so it's "working." What's missing is everything the `<form>` element does for free: pressing Enter in the password field does nothing (users hit Enter, see nothing, hit it again, then hunt for the button). Password managers and browser autofill, which key off form structure, fill less reliably or offer to save nothing. `required` and `type="email"` validation never fire because there's no submit event to trigger them. On mobile, the software keyboard's "go" key is dead.

The inverse mistake appears when a `<form>` does exist: the AI puts the handler on the button's `onClick` instead of the form's `onSubmit`, so Enter-key submission (which fires submit, not the button's click in all paths) bypasses the handler or triggers a full page reload because nobody called `preventDefault` on the actual submit event. Or every auxiliary button inside the form — "show password," "clear," "add row" — is left as default `type` (which is `submit`), so clicking "show password" submits the half-finished form.

The AI does this because click is the only interaction it simulates. Enter, autofill, and the mobile keyboard are submission paths that exist for users but not in the AI's verification loop.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Native Form Submit Working

ALWAYS build forms as a real `<form>` with the logic in `onSubmit`. Enter-to-submit, native validation, autofill, and password managers all hang off the form element — a div of inputs with an onClick button has none of them.

- Structure: `<form onSubmit={handleSubmit}>` with a `<button type="submit">`. The handler calls `event.preventDefault()` (when submitting via JS) and lives on the form, not the button — that's what makes Enter in any field, the mobile keyboard's go key, and the button all converge on one code path.
- EVERY other button inside a form gets explicit `type="button"`. The default type is `submit`, so an untyped "show password" or "remove item" button silently submits the form. This is the single most common form bug; type every button.
- Use real input types (`email`, `password`, `tel`, `number`, `url`) and `autocomplete` attributes (`autocomplete="email"`, `"current-password"`, `"new-password"`). They drive mobile keyboards, autofill, and password managers — stripping them to generic `text` breaks all three.
- Don't suppress native validation reflexively. `required`, `minLength`, and pattern checks are free; add `noValidate` only when the project's validation library replaces them with something at least as visible.
- Never block paste, autofill, or autocomplete on credential or code fields ("paste disabled for security" is security theater that mostly punishes password-manager users).
- Test the paths you didn't click: would Enter from the last field submit? Would clicking each auxiliary button leave the form unsubmitted?

**Red flags that you're about to violate this:**

- "The button's onClick submits it, the form tag is redundant."
- "I'll wire up Enter handling with a keydown listener later if needed."
- "It's just a toggle button inside the form, no type needed."
- "preventDefault on the button click covers the reload."
- "Generic text inputs are simpler than fiddling with types."
- "Clicking submit works, the form is done."

---

## Why It Works

1. **It bundles the invisible beneficiaries.** Enter, autofill, password managers, and mobile keyboards are four user paths the AI never exercises; tying them all to the `<form>`/`onSubmit` structure makes one structural choice carry all four.
2. **It elevates `type="button"` to a per-button rule.** The implicit-submit default is the most-shipped form bug because it requires knowing a non-obvious spec fact; stating it as "type every button" removes the knowledge dependency.
3. **It distinguishes onSubmit from onClick mechanically.** The AI treats them as synonyms; explaining that only submit unifies all submission paths shows why the placement is correctness, not style.
4. **It ends with the two untested paths.** "Would Enter work? Would this button submit?" are five-second checks that catch ninety percent of violations before they ship.

## Origin

An assistant added a "show password" toggle to a working login form and left the new button untyped. Every user who tapped the eye icon submitted a login attempt with whatever was in the fields — usually failing, sometimes locking accounts after repeated toggles tripped the attempt limit. The bug shipped because clicking the toggle visually toggled the password just fine; the stray submission was invisible unless you watched the network tab. One attribute fixed it.
