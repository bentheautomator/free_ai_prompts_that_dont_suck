---
title: Use Real Links for Navigation
slug: use-real-links-for-navigation
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: high
one_liner: "Stops onClick navigation that breaks new-tab, copy link, and middle-click"
---

# Use Real Links for Navigation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from implementing navigation as click handlers on non-link elements, killing open-in-new-tab, copy-address, middle-click, and crawlability in one stroke.

**[Copy-paste ready version](../../install/use-real-links-for-navigation.md)** — just the instruction block, no explanation.

## The Problem

Navigation from an AI assistant often ships as `<div onClick={() => navigate('/products/' + id)}>`, or `<a href="#" onClick={...}>`, or a `<button>` that calls `router.push`. All three navigate when left-clicked, which is the only test they'll ever face before shipping. Everything else a link does is gone: Cmd/Ctrl+click opens nothing in a new tab (or worse, navigates the current one — destroying a form the user was filling elsewhere on the page). Right-click offers no "Copy link address" or "Open in new window." Middle-click does nothing. Hover shows no destination in the status bar. Screen readers don't list it among the page's links. Crawlers don't follow it. And `href="#"` adds its own gift: a stray history entry and a scroll-to-top whenever `preventDefault` is forgotten on one code path.

The distinction the AI is missing is semantic, and it's load-bearing: a *link* takes you to a URL (and users hold a learned toolkit for URLs — new tabs, sharing, bookmarking); a *button* performs an action. JS-navigation handlers build something that's secretly neither. Users with twenty years of muscle memory Cmd+click a product card, get nothing, and experience the app as subtly broken in a way they articulate as "this site fights me."

Assistants do it because `onClick` + imperative navigate is one uniform pattern that works for any element shape, while a proper link demands the right component and an `href` — slightly more thought, invisibly more value.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Real Links for Navigation

If activating it changes the URL, it's a link: an `<a href>` (or the router's `<Link to>`), NEVER a click handler on a div, span, or button.

Real links carry a toolkit users rely on — new tab, copy address, middle-click, status-bar preview, screen reader link lists, crawlability. An onClick that calls `navigate()` discards all of it for zero benefit.

- In-app navigation in an SPA: the router's link component (`<Link to=...>`, `<router-link>`, framework equivalent). It renders a true `<a href>` and intercepts plain left-clicks for client-side routing while letting modified clicks (Cmd/Ctrl/middle/Shift) reach the browser. That split is the whole point — reimplementing it in onClick gets it wrong.
- Never `href="#"` or `href="javascript:void(0)"` as a mount point for handlers. If there's a destination, put it in `href`; if there's no destination, the element is a button — use `<button>`.
- The decision rule: changes the URL → link; performs an action staying on the page → button. "Log out" is a button. "View order" is a link. A card that opens a detail page is a link even though it's a card — wrap or embed a real `<Link>` and extend its hit area with CSS if needed.
- Programmatic `navigate()`/`router.push()` is for navigation that *isn't* user-clicks-a-thing: post-submit redirects, auth bounces, wizard advancement. Using it as a click handler's body on a clickable element is the anti-pattern.
- Don't suppress link affordances: no `onClick={e => e.preventDefault()}` wrappers around real links to force SPA behavior the Link component already provides, and never intercept modified clicks.
- Buttons styled as links and links styled as buttons are fine — CSS is free; semantics aren't.

**Red flags that you're about to violate this:**

- "onClick with navigate() does the same thing as a Link."
- "The whole card is clickable, so the div gets the handler."
- "href='#' stops it from actually navigating, then my JS takes over."
- "Nobody middle-clicks in a web app."
- "I'll preventDefault and handle routing manually for more control."
- "It navigates when I click it — navigation works."

---

## Why It Works

1. **It gives the one-question classifier.** "Does the URL change?" resolves every link-vs-button ambiguity instantly, including the card case where the element's shape misleads the AI.
2. **It explains what Link components actually do.** The AI treats `<Link>` and `onClick`+`navigate` as equivalent because both navigate on left-click; naming the modified-click passthrough reveals the non-equivalence it can't see.
3. **It assigns programmatic navigation a legitimate home.** Banning `navigate()` outright would break redirects; scoping it to non-click flows keeps the API while closing the abuse.
4. **It pre-counters "nobody does that in a web app."** Power-user affordances are invisible in the AI's single-click test, so the rule lists them as the deliverable rather than trusting them to be imagined.

## Origin

An analytics product rebuilt its report list with clickable row divs calling `router.push`. Within days, a forum thread titled "can no longer open reports in tabs" collected the product's heaviest users — analysts who habitually Cmd+clicked six reports into six tabs every morning, and who now got six failed nothing-clicks. The feature regression never appeared in QA because every test script left-clicked once. Restoring `<Link>` rows took an hour; the thread had already become the top result for the product's name plus "annoying."
