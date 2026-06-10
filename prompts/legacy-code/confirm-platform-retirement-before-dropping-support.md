---
title: Confirm Platform Retirement Before Dropping Support
slug: confirm-platform-retirement-before-dropping-support
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Keeps platform support code until the business confirms the platform is dead"
---

# Confirm Platform Retirement Before Dropping Support

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from stripping out support code for platforms it considers obsolete while the team still ships to them.

**[Copy-paste ready version](../../install/confirm-platform-retirement-before-dropping-support.md)** — just the instruction block, no explanation.

## The Problem

Platform support code is loud about its age and silent about its necessity. Polyfills for an old browser, `#ifdef` blocks for a 32-bit build, fallbacks for an Android API level from another era, path handling for an OS the assistant thinks nobody runs — all of it pattern-matches as cruft. The AI's mental model of "platforms that matter" comes from training data dominated by mainstream developer chatter, where old browsers are a punchline and 32-bit is prehistory.

Which platforms a product supports isn't an engineering aesthetic; it's a business commitment. The old browser is in the support matrix because the biggest customer's locked-down desktop fleet runs it. The ancient Android level is supported because the product ships on cheap field hardware. The 32-bit build exists for a point-of-sale terminal still under contract. None of that is visible in the code — what's visible is the ugly fallback, and the AI deletes the fallback during a refactor because "no one targets that anymore."

The breakage often passes CI, because CI tests the platforms engineers like, not the platforms customers run. It surfaces as a support ticket from exactly the customer whose contract made the support code exist.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Confirm Platform Retirement Before Dropping Support

NEVER remove platform-specific support code — polyfills, fallbacks, conditional builds, OS or browser or architecture branches — based on your judgment of which platforms are obsolete. The support matrix is a business decision recorded somewhere other than the code, and your training-data sense of "nobody uses that" is not it.

Before touching platform support code:

- Find the actual support matrix: browserslist config, minimum SDK/OS settings, build targets in CI, compatibility pages in docs, sales or contract requirements the user can check. A platform listed anywhere there is supported, full stop.
- Treat build configs as contracts. A 32-bit target in the build matrix, an old browser in browserslist, a low minSdkVersion: these are declarations that someone ships there, however unfashionable.
- Never drop a platform implicitly. Using an API unavailable on a supported platform, or deleting its fallback, is dropping the platform without saying so — the worst version, because nothing announces it until a user on that platform hits it.
- If you believe a platform should be dropped, propose it as its own decision: name the platform, what removing support saves, and who must confirm zero usage. The user takes it from there.
- When adding code, write to the declared floor, not your preferred floor. The supported platforms constrain which language features and APIs you may use, whether or not local tooling complains.

**Red flags that you're about to violate this:**
- "Nobody develops for that browser anymore."
- "That OS version is a rounding error in global market share."
- "This polyfill is for a platform that's been dead for years."
- "Modern devices all support this API, the fallback is pointless."
- "I'll use the new syntax; surely their toolchain targets something recent."
- "32-bit support in 2026 can't be real."

---

## Why It Works

1. **It names the bad oracle.** The AI was consulting its training-data zeitgeist for support decisions; pointing at the real oracles — browserslist, SDK floors, build matrices, contracts — replaces opinion with lookup.
2. **It distinguishes global market share from local install base,** which is the precise confusion driving the failure: 0.3% of the world can be 100% of one paying customer's fleet.
3. **The implicit-drop framing catches the quiet variant.** Most platform breakage isn't a deleted polyfill; it's a casually-used modern API. Defining that as "dropping a platform without saying so" brings it under the same rule.
4. **Routing drop proposals to a named decision** acknowledges platforms do get retired — through someone with usage data and contract knowledge, not through a refactor.

## Origin

A frontend refactor replaced a clunky date-input fallback with the native control, on the grounds that every modern browser had supported it for years. The product's largest customer ran kiosk terminals on an embedded browser frozen by their IT certification process — the entire reason the fallback existed, as the browserslist entry and a line in the sales contract both recorded. Kiosk users couldn't enter dates for two days. The customer's escalation reached the vendor's leadership before the bug report reached the developers, which is the order nobody wants.
