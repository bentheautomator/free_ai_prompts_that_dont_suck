---
title: Never Weaken CSP to Make an Error Go Away
slug: never-weaken-csp-to-fix-errors
category: security
tags: [universal, security, headers]
works_with: all
severity: high
one_liner: "AI adding unsafe-inline or unsafe-eval to silence a CSP violation"
---

# Never Weaken CSP to Make an Error Go Away

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from gutting the Content-Security-Policy because the console showed a blocked-resource error.

**[Copy-paste ready version](../../install/never-weaken-csp-to-fix-errors.md)** — just the instruction block, no explanation.

## The Problem

The console says `Refused to execute inline script because it violates the following Content Security Policy directive...`. The AI reads this as breakage, finds the CSP header, and "fixes" it: adds `'unsafe-inline'` to `script-src`, or `'unsafe-eval'` because a library complained, or widens a source list to `https:` or `*` because the CDN domain was tedious to look up. The feature works again. The policy, which existed to make XSS payloads inert, now permits exactly the inline scripts and eval calls that XSS payloads are made of. A CSP with `unsafe-inline` in `script-src` is decorative.

This is a textbook example of the AI optimizing for the visible error over the invisible control. Someone spent real effort deploying that policy; the AI undoes it in one line because the violation report looks like a bug and the loosened policy makes it disappear. The same motion happens with `frame-ancestors` when an iframe won't load, and with `connect-src` when a fetch is blocked — sometimes loosening is genuinely the right call (a new legitimate API endpoint), which is why the rule must distinguish "add the specific origin" from "add a wildcard or unsafe keyword."

Modern CSP has good answers for every legitimate blocked case: nonces, hashes, refactoring the inline handler into a file. They cost minutes, not the policy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Weaken CSP to Make an Error Go Away

NEVER fix a CSP violation by adding `'unsafe-inline'`, `'unsafe-eval'`, a wildcard, or a broad scheme source. Fix the code to comply with the policy, or add the single specific origin that's legitimately needed.

A CSP violation means the policy is working. `unsafe-inline` in `script-src` switches the XSS protection off while leaving the header up for show.

- Blocked inline script or `onclick=` handler: move the code into an external file, or use the nonce the framework already emits (`<script nonce="{{ csp_nonce }}">`), or add the script's hash (`'sha256-...'`) to the policy.
- Library demands `'unsafe-eval'`: look for the build that doesn't (e.g., precompiled templates, the CSP-compatible bundle). Only if none exists, surface the tradeoff to the user instead of silently adding it.
- Blocked external resource: add that exact origin (`https://cdn.example.com`), never `https:`, `*`, or a parent wildcard like `*.cloudfront.net` that thousands of strangers can host content on.
- Blocked inline styles: prefer classes/external CSS; `'unsafe-inline'` in `style-src` is lower stakes than in `script-src` but still a last resort, not a reflex.
- Never delete the CSP header, switch it permanently to `Content-Security-Policy-Report-Only`, or comment it out "while we develop." Report-only is a rollout tool, not a fix.
- Treat any diff that touches the CSP as security-relevant: state in your summary exactly which directive changed and why the narrowest version was chosen.

**Red flags that you're about to violate this:**
- "Adding unsafe-inline unblocks this in one line..."
- "The analytics snippet needs inline scripts, every site allows this..."
- "I'll wildcard the CDN domain so we never hit this again..."
- "We can tighten the policy back up before release..."
- "unsafe-eval is required by the framework, so there's no choice..."
- "Report-only mode keeps the policy while making the errors stop..."

---

## Why It Works

1. **It reframes the violation as the control functioning.** The AI's root error is classifying the console message as a defect. Once the message means "policy working," the loosening fix stops being a fix.

2. **It supplies the compliant alternatives in order.** Nonces, hashes, and externalizing scripts are the moves AIs don't know to reach for; listing them makes compliance cheaper than weakening.

3. **It draws the line between specific origins and wildcards.** Sometimes the policy genuinely needs a new entry. Permitting the exact-origin fix keeps the rule realistic, which keeps it followed.

4. **It blocks the report-only laundering trick.** Switching enforcement off "temporarily" looks responsible and is functionally identical to deletion; naming it closes the most respectable-looking escape route.

## Origin

A third-party chat widget broke after a hardening sprint shipped a strict CSP. Asked to fix the widget, the assistant added `'unsafe-inline' 'unsafe-eval'` to `script-src` and `*` to `connect-src`, and the widget came back to life. So did an old stored-XSS payload in a legacy comments table that the CSP had been silently neutralizing for a year. The correct fix, recorded in the postmortem, was the widget vendor's documented nonce integration: six lines.
