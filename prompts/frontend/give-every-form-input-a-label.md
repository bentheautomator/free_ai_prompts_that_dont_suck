---
title: Give Every Form Input a Label
slug: give-every-form-input-a-label
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: high
one_liner: "Stops placeholder-as-label inputs that screen readers announce as nothing"
---

# Give Every Form Input a Label

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping inputs whose only identification is a placeholder, leaving screen readers, autofill, and anyone mid-typing with an anonymous field.

**[Copy-paste ready version](../../install/give-every-form-input-a-label.md)** — just the instruction block, no explanation.

## The Problem

Modern form design trends toward minimal, and AI assistants have absorbed the worst version of it: `<input placeholder="Email address" />` with no label anywhere. It looks labeled — the gray text says what the field is — so the AI's visual check passes. But a placeholder is not a label. It vanishes the moment the user types, so anyone interrupted mid-form returns to a grid of anonymous boxes holding half-remembered values. Screen readers may announce it inconsistently or not at all, so the field is just "edit text." Autofill heuristics lose a signal. Low-vision users get placeholder-gray contrast that often fails WCAG by itself.

The related failure is the decorative label: a `<label>` element that exists but isn't connected — no `for`/`htmlFor` matching the input's `id`, or an `id` duplicated across the page so the association is ambiguous. Visually identical to correct, programmatically absent. Clicking the label doesn't focus the input (the cheap tell), and assistive tech reads nothing.

Assistants produce both because the rendered pixels are indistinguishable from the accessible version, and because `htmlFor`/`id` pairing is bookkeeping with no visible payoff. When a designer's mock shows no visible label, the AI obliges with no label at all, rather than a visually-hidden one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Give Every Form Input a Label

EVERY form control gets a programmatically associated label. A placeholder is not a label — it disappears on input and is unreliable for assistive tech.

- Default pattern: `<label htmlFor="email">Email address</label><input id="email" />`, or wrap the input inside the label. The `id` must be unique on the page (in reusable components, generate it — `useId` — don't hardcode it).
- The design shows no visible label? Use a visually-hidden label (the project's `.sr-only`/`.visually-hidden` class) or `aria-label="Email address"` — not nothing. Minimal design is a styling decision, not a semantics decision.
- Placeholders are for format hints (`placeholder="name@example.com"`), supplementary to a label, never instead of one.
- Checkboxes and radios especially: the clickable text next to them must be their real `<label>`, both for screen readers and because it makes the text a click target — a bare `<span>` next to a checkbox is two bugs.
- Selects, textareas, and custom widgets (comboboxes, date pickers) follow the same rule; for custom widgets, ensure the visible label is wired via `aria-labelledby` to the focusable element.
- Verify the association the cheap way: clicking the label text must focus (or toggle) the control. If it doesn't, the wiring is broken regardless of how it looks.
- Group related controls: radio groups and checkbox sets get a `<fieldset>` with a `<legend>` naming the question, or the individual options read as context-free fragments.

**Red flags that you're about to violate this:**

- "The placeholder says what the field is, that's the label."
- "The mock has no labels, so the form has no labels."
- "I'll add the label element; wiring the for attribute is just ceremony."
- "It's one search box, everyone knows what it's for."
- "I'll reuse id='input' like the other instances do."
- "The checkbox text is right next to it, the association is obvious."

---

## Why It Works

1. **It severs "visible text near the input" from "labeled."** The AI's check is visual adjacency; the rule replaces it with programmatic association, which is the thing assistive tech and click-to-focus actually use.
2. **It handles the minimal-design order correctly.** "Mock shows no label" is the top rationalization, and visually-hidden labels let the AI satisfy both the designer and the screen reader instead of choosing.
3. **It supplies a free verification.** Click-the-label-focuses-the-input is a one-second test that catches every broken `for`/`id` pair, including the duplicate-id variant that looks wired but isn't.
4. **It names checkboxes as the double failure.** Unlabeled checkbox text costs both semantics and tap target, and it's the case AIs skip most because the text is "right there."

## Origin

An insurance quote form built by an assistant used placeholders as labels across eleven fields. A user filling it out took a phone call mid-form and returned to find seven boxes of digits — policy number? phone? ZIP? — with no way to tell which was which except deleting their input to resurrect the placeholders. They abandoned the form. Analytics later showed the form's mid-completion abandonment was triple the old version's, and the accessibility audit the company eventually commissioned flagged all eleven fields in its first pass.
