---
title: Never Win CSS Fights With !important
slug: never-win-css-fights-with-important
category: frontend
tags: [universal, frontend, css]
works_with: all
severity: medium
one_liner: "Stops !important escalation that makes stylesheets unmaintainable"
---

# Never Win CSS Fights With !important

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from slapping `!important` on a rule to beat specificity instead of finding out why the style isn't applying.

**[Copy-paste ready version](../../install/never-win-css-fights-with-important.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant changes a style, reloads, and the style doesn't apply — some existing rule with higher specificity wins. The honest fix takes investigation: open devtools, find the competing rule, adjust the selector or the cascade order. The fix the AI actually writes is `color: red !important;`. The style applies, the screenshot looks right, the task is "done." What shipped is an escalation: the next person (often the same AI, next session) who needs to override *that* rule now also needs `!important`, plus a more specific selector, and the stylesheet begins its slide into a specificity arms race nobody can win without inline styles.

Assistants reach for `!important` because it always works on the first try and the cost is invisible in the diff. A one-line change that produces the requested pixel output is locally indistinguishable from a correct change. The damage only appears weeks later, when a theme override or responsive variant silently fails because some buried `!important` outranks it.

The same instinct shows up as selector inflation: `.sidebar .nav ul li a.link` written purely to out-specific an existing rule, which is `!important` with extra steps.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Win CSS Fights With !important

NEVER add `!important` to make a style apply. If your rule is losing, find out what it's losing to and fix the cascade, not the symptom.

`!important` doesn't resolve a specificity conflict — it escalates it, and every future override of that property now needs `!important` too.

- When a style doesn't apply, identify the winning rule first (devtools, or grep the codebase for the property and selector). Name the conflict before writing the fix.
- Prefer, in order: put the rule in the right layer/file so source order wins; match the existing selector's specificity exactly; use `:where()` to lower specificity of broad rules; restructure with `@layer` if the project uses it.
- Never artificially inflate selectors (`.card.card`, `div.sidebar ul li a`) to win a fight — that is `!important` in disguise and breaks just as badly.
- Acceptable uses of `!important` are narrow: utility classes explicitly designed to always win (some utility-CSS conventions), and overriding inline styles injected by third-party scripts you cannot modify. In both cases, say so in a comment.
- If you find yourself adding `!important` to beat an existing `!important`, stop — that's the arms race. Fix or flag the original instead.
- Never copy `!important` from a nearby rule "for consistency." Each instance needs its own justification.

**Red flags that you're about to violate this:**

- "My style isn't applying, !important will sort it out."
- "I don't want to touch the existing selector, so I'll just force this one."
- "It's only one property, one !important won't hurt."
- "The old rule already uses !important, so mine has to as well."
- "I'll make the selector more specific by repeating the class."
- "This is faster than figuring out where the other style comes from."

---

## Why It Works

1. **It forces the diagnostic step the AI skips.** The failure isn't malice, it's that `!important` works without understanding the conflict; requiring the AI to name the winning rule first makes the lazy path unavailable.
2. **It closes the selector-inflation loophole.** An AI told only "no !important" will write `.card.card.card` instead — same escalation, different syntax — so the rule bans the disguise explicitly.
3. **It defines the legitimate exceptions narrowly.** Third-party inline styles are a real case; carving them out (with a required comment) stops the AI from treating every inconvenience as that exception.
4. **It interrupts the arms race at the recognizable moment.** "!important to beat !important" is the exact point where stylesheets become unmaintainable, and naming that moment gives the AI a tripwire.

## Origin

A team asked their assistant to make alert banners match new brand colors. The new rule lost to an old themed selector, so the assistant added `!important` to four properties. It looked perfect. Two sprints later the same assistant was asked to build a dark mode; the theme variables applied everywhere except alerts, and the "fix" it generated was `!important` on every dark-mode alert rule. By the time a human looked, the alert stylesheet had 23 `!important` declarations fighting each other and the only way out was a rewrite.
