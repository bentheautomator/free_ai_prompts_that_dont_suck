---
title: Look at the Rendered Page Before Claiming the UI Works
slug: look-at-the-rendered-page-before-claiming-the-ui-works
category: verification
tags: [universal, verification, frontend]
works_with: all
severity: high
one_liner: "Declaring UI changes working from the code, without ever viewing the result"
---

# Look at the Rendered Page Before Claiming the UI Works

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring visual changes correct without ever observing what actually renders.

**[Copy-paste ready version](../../install/look-at-the-rendered-page-before-claiming-the-ui-works.md)** — just the instruction block, no explanation.

## The Problem

UI work has a property most code doesn't: the deliverable is what a human sees. An assistant changes a layout, restyles a modal, fixes "the button is cut off on mobile" — and reports it done based on the JSX and CSS reading correctly. Nobody, human or machine, has looked at the result. The component can mount, the tests can pass, the types can check, and the modal can still open behind the overlay, the button can still be cut off, the text can be white on white, and the layout can collapse at exactly the width the user complained about.

This happens because rendering is where the assistant's strongest tools stop. Code is fully legible to it; pixels require a browser, a screenshot, or a human's eyes — an extra loop that costs setup. So verification quietly substitutes the legible thing for the asked-about thing: "the flex properties are correct" stands in for "the layout looks right." But CSS is famously non-local — a parent's `overflow`, a z-index stack, an inherited line-height — so correct-reading styles routinely produce wrong-looking pages. Visual correctness is an emergent property; it can only be observed, not derived.

The user then opens the page expecting the described fix and sees the bug, sometimes wearing a new outfit. For visual work, that first impression *was* the acceptance test, and it just failed in front of the one person it needed to pass for.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Look at the Rendered Page Before Claiming the UI Works

NEVER claim a visual change works, looks right, or is fixed unless the rendered result has actually been observed — by you via screenshot or browser tooling, or explicitly deferred to the user. Code that should render correctly is a hypothesis about pixels.

The core problem: visual correctness is emergent — parent overflow, z-index stacks, inherited styles, and real content lengths all bend the result — so styles that read right routinely render wrong. Only looking at the screen verifies the screen.

- If you have any rendering capability (screenshot tool, headless browser, dev-server preview), use it: load the actual page, navigate to the actual state (open the modal, trigger the error, populate the list), and look at the changed region before claiming anything.
- Verify at the conditions named in the task: the reported viewport width, the long username, the empty state. A fix for "broken on mobile" verified only at desktop width is unverified.
- Check interaction visually when the change involves it: hover, focus, open/close, scroll. A correct first frame doesn't verify a dropdown that opens off-screen.
- If you cannot render anything, say so and structure the handoff: "styles updated — please verify visually: the modal at mobile width, the button with long labels. I have not seen this render."
- A clean console does not substitute for looking: a console with no errors over a broken layout is still a broken layout.
- Describe what you observed, not what the code intends: "screenshot shows the button fully visible at 375px" beats "the button should no longer be cut off."

**Red flags that you're about to violate this:**
- "The flexbox values are right, so the layout is right..."
- "The component renders in the test, so it looks fine..."
- "I'll describe the fix as done; the user will see it anyway..."
- "Checking one viewport is enough — CSS scales..."
- "The styles are simple; no way they interact badly with the parent..."
- "Spinning up a browser for a padding change is overkill..."

---

## Why It Works

1. **It reframes code-reading as hypothesis, not evidence.** "Styles that read right routinely render wrong" plus the named mechanisms (overflow, z-index, inheritance) breaks the inference the model leans on — that legible code implies a correct result.

2. **It binds verification to the task's conditions.** "Broken on mobile" defines where the proof must happen; requiring the named viewport/state blocks the desktop-width check from impersonating it.

3. **It scripts the no-render handoff.** When the assistant genuinely can't see pixels, the explicit "I have not seen this render, check these two things" turns a hidden gap into a usable checklist — honesty with a function.

4. **It distinguishes observation language from intent language.** "Screenshot shows X at 375px" is unfakeable without the screenshot; mandating observed phrasing makes the claim and the act inseparable.

## Origin

A ticket read "save button unreachable on small screens." The assistant adjusted the container's height handling, confirmed the CSS logic was sound, and closed with "the button is now accessible on all viewports." It had rendered the page zero times. The parent element's `overflow: hidden` — three components up — still clipped the button at exactly the reported widths. The user verified the fix on their phone in the meeting where they'd planned to demo it. The second attempt began with a screenshot at 375px, which is how it should have begun the first time.
