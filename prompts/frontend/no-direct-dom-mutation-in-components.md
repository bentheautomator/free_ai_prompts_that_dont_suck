---
title: No Direct DOM Mutation in Components
slug: no-direct-dom-mutation-in-components
category: frontend
tags: [universal, frontend, react]
works_with: all
severity: high
one_liner: "Stops querySelector and manual DOM edits inside framework-managed trees"
---

# No Direct DOM Mutation in Components

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reaching around React/Vue/Svelte with `document.querySelector` and manual DOM mutation, creating state the framework will overwrite or trip on.

**[Copy-paste ready version](../../install/no-direct-dom-mutation-in-components.md)** — just the instruction block, no explanation.

## The Problem

Inside a React component, the AI needs to hide an element, so it writes `document.querySelector('.banner').style.display = 'none'`. It needs to update a counter badge, so it sets `.textContent`. It needs a class toggled, so `classList.add('active')`. Each line works — once, in the moment it runs. Then the framework re-renders, rebuilds that part of the tree from its own state, and the manual change silently evaporates: the banner is back, the badge shows the old number, the class is gone. Or the inverse: the framework reconciles against DOM it didn't produce and removes nodes the manual code added, leaving the next `querySelector` returning null and the handler throwing.

This is two sources of truth fighting over one tree, and the framework always wins eventually — at a time determined by whatever unrelated state change triggers the next render. That makes the failures intermittent: the hack holds through the demo and dies in production when a notification elsewhere re-renders the layout. Selector-based access adds its own fragility: `.banner` matches the first one on the page, not necessarily yours, and breaks when someone renames a CSS class for styling reasons.

Assistants write this because direct DOM manipulation is the most-represented pattern in their training data, and because it produces an immediately observable effect — more satisfying than tracing where the `visible` flag should live.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Direct DOM Mutation in Components

NEVER mutate DOM that the framework renders. If a component's output should change, change the state that renders it — `style`, `textContent`, `classList`, and `innerHTML` edits to framework-managed nodes are writes the next render will erase or fight.

The framework owns its tree. Manual edits create a second source of truth that survives only until the next render, which makes every such hack an intermittent bug.

- Hiding/showing, text changes, class toggles: these are render outputs. Add or change the state/prop that drives them (`{visible && <Banner/>}`, `className={isActive ? 'active' : ''}`), even when the manual edit is fewer keystrokes.
- Never locate your own elements with `document.querySelector`/`getElementById` inside a component. Use a ref. Selectors couple behavior to styling-owned class names and grab whichever match comes first, including other instances of your component.
- Refs are for the operations the framework genuinely doesn't model: `.focus()`, `.scrollIntoView()`, measuring (`getBoundingClientRect`), play/pause on media, canvas contexts. Read-and-call is fine; writing styles/content/children through a ref re-creates the original problem with better aim.
- Wrapping a non-framework library (chart, map, rich-text editor) that must own real DOM: give it a ref'd container the framework renders but never fills, initialize in an effect, destroy in cleanup, and route all updates through the library's API — never let the framework and the library both write inside that container.
- Escaping to `document.body` (modals, toasts) is what portals are for, not manual `appendChild`.
- If you find yourself mutating DOM because "the state for this is too far away," the finding is "the state is in the wrong place" — move it, don't bypass it.

**Red flags that you're about to violate this:**

- "querySelector and one style change is way less code than threading state."
- "The framework doesn't need to know about this little tweak."
- "I'll update the badge text directly, re-rendering the list is overkill."
- "classList.toggle works right now, I checked."
- "The state lives three components up, easier to just touch the DOM."
- "I'll appendChild the modal to body so it escapes the overflow."

---

## Why It Works

1. **It names the erasure mechanism.** The AI sees its mutation work and concludes correctness; learning that the next unrelated render reverts it explains why "I checked and it works" is exactly the false signal.
2. **It draws the ref line at read-and-call vs write.** A bare "use refs instead" rule just relocates the mutations; distinguishing focus/measure/play (fine) from styles/content/children (same bug) keeps the escape hatch from swallowing the rule.
3. **It handles the third-party-library case explicitly.** Chart and editor wrappers are the one place manual DOM is correct, and without the container-ownership pattern the AI either breaks the rule or breaks the library.
4. **It reframes "state is too far away" as the actual finding.** That feeling is the precise moment the hack gets written; converting it into a state-placement diagnosis routes the AI to the real fix.

## Origin

An assistant implemented "dismiss announcement banner" with `document.querySelector('.announcement').remove()`. It worked in every test. In production, dismissing the banner and then receiving any live notification — which re-rendered the header — resurrected the banner, because the `dismissed` fact lived nowhere the framework could see. Users reported the banner as "undismissable," QA couldn't reproduce it without a notification firing, and the eventual fix was a boolean in state plus deleting the querySelector line that had cost three debugging sessions.
