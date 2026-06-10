---
title: Never Disable Viewport Zoom
slug: never-disable-viewport-zoom
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: high
one_liner: "Stops user-scalable=no and maximum-scale=1 from blocking pinch zoom"
---

# Never Disable Viewport Zoom

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping viewport meta tags that block pinch-zoom, locking low-vision users out of the one tool that makes small text readable.

**[Copy-paste ready version](../../install/never-disable-viewport-zoom.md)** — just the instruction block, no explanation.

## The Problem

The viewport meta tag AI assistants emit for "a mobile-friendly page" is frequently this one: `<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">`. The last two clauses disable pinch zoom. For anyone over forty reading 14px text, anyone with low vision, anyone trying to read a dense chart or tap a small link, zoom *is* the accessibility layer — and this tag, copied wholesale from a decade of cargo-culted boilerplate, turns it off sitewide in one line.

The historical excuses are dead. `user-scalable=no` was spread around 2013 to kill the 300ms tap delay and to stop accidental zoom during touch interactions; the tap delay has been fixed by `width=device-width` alone for years, and iOS Safari now (rightly) ignores the directive in many cases — which means the tag doesn't even reliably do the broken thing it promises, it just fails WCAG 1.4.4 and breaks the browsers that still honor it. The adjacent failure is the indirect version: the AI "fixes" the iOS behavior where focusing a sub-16px input auto-zooms the page by adding `maximum-scale=1`, instead of the correct fix — making input font-size 16px.

The AI ships this because the full-fat viewport tag appears in countless tutorials and templates as a single memorized unit. It isn't deciding to block zoom; it's autocompleting boilerplate that happens to.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Disable Viewport Zoom

NEVER ship `user-scalable=no` or `maximum-scale=1` in a viewport meta tag. Pinch zoom is how low-vision users read your page; disabling it is an accessibility failure with no compensating benefit.

The correct viewport tag is exactly: `<meta name="viewport" content="width=device-width, initial-scale=1">`. Nothing else belongs in it.

- The reasons this boilerplate existed are obsolete: the 300ms tap delay is already eliminated by `width=device-width`, and modern iOS ignores `user-scalable=no` anyway — the directive fails WCAG 1.4.4 (which requires text resizable to 200%) without delivering anything.
- iOS auto-zooming when a user focuses an input? That happens because the input's font-size is under 16px. Fix: `input, select, textarea { font-size: 16px; }` (or 1rem with a 16px root). Never fix it by capping zoom for the whole page.
- A map, canvas, or image-editor element where pinch must mean pan/zoom-the-widget: handle the gesture on that element (`touch-action` CSS, pointer event handlers) — never by disabling page zoom globally.
- When touching any HTML template, layout file, or index.html that already contains `maximum-scale`, `minimum-scale`, or `user-scalable=no`, remove the offending clauses and say so — it's a one-line a11y fix riding along for free.
- The same prohibition applies to JS that calls `preventDefault()` on pinch/`gesturestart` events at the document level to "stabilize the layout." If zoom breaks your layout, the layout is the bug.

**Red flags that you're about to violate this:**

- "The standard mobile viewport tag includes user-scalable=no."
- "Pinch zoom breaks the layout, so I'll lock the scale."
- "maximum-scale=1 stops that annoying iOS input zoom."
- "It's a web app, not a page — apps don't zoom."
- "The template I'm matching already has it, I'll keep it consistent."
- "Users can use the OS accessibility zoom if they really need it."

---

## Why It Works

1. **It replaces the memorized unit.** The failure is autocompletion of dead boilerplate, so the rule supplies the exact correct tag to autocomplete instead — same effort, no harm.
2. **It debunks the two justifications by name.** Tap delay and iOS input zoom are the only reasons the AI ever articulates; pre-refuting both (obsolete; fix is 16px inputs) leaves the directive with no story.
3. **It handles the widget-zoom case before it's used as a loophole.** Maps and canvases are the one real pinch conflict, and scoping the fix to the element keeps "but my map" from re-justifying the global ban.
4. **It deputizes the AI for cleanup.** Most instances are pre-existing copy-paste; making removal-on-contact part of the rule converts every routine edit into remediation.

## Origin

A restaurant chain's ordering site shipped with `user-scalable=no` in a template an assistant had generated early in the project. The menu rendered nutritional info at 11px. Older customers couldn't zoom it on Android (which honors the directive), and the franchise started getting complaints that the menu was "printed too small" — on a website. An accessibility consultant's first finding was the viewport tag; deleting fourteen characters resolved a complaint category that had been blamed on the design for months.
