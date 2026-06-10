---
title: Use Design Tokens, Not Hardcoded CSS Values
slug: use-design-tokens-not-hardcoded-css-values
category: frontend
tags: [universal, frontend, css]
works_with: all
severity: medium
one_liner: "Stops raw hex colors and magic spacing where a token system exists"
---

# Use Design Tokens, Not Hardcoded CSS Values

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing literal hex colors, spacing values, and font sizes in codebases that define them as tokens — the leak that breaks theming and visual consistency.

**[Copy-paste ready version](../../install/use-design-tokens-not-hardcoded-css-values.md)** — just the instruction block, no explanation.

## The Problem

The project defines `--color-primary`, a spacing scale, and a Tailwind theme — and the AI, asked for a button, writes `background: #3b82f6; padding: 9px 14px; font-size: 15px`. The color is eyeballed from a nearby component or remembered from training data; the spacing came from nowhere on the project's 4px scale; the font size matches no step in the type scale. It renders fine. It's even *approximately* on-brand. And it has just opted out of every system the tokens exist to provide.

The bill arrives with the first global change. Dark mode ships: every tokenized surface flips, the hardcoded `#3b82f6` button glows unchanged on the dark background. The brand color updates: grep finds 200 token references and misses the 30 hex approximations, so the app wears two blues for a quarter. Off-scale spacing values mean components misalign by 1-2px in compositions, the kind of wrongness users feel but can't name. Each literal is also a vote for the next one — assistants copy nearby code, so one `#333` becomes twelve.

The AI hardcodes because a literal value requires no codebase lookup: the token's name must be discovered, the hex can be invented. Under any time pressure, invention wins unless the lookup is mandated.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Design Tokens, Not Hardcoded CSS Values

If the project has a token system — CSS custom properties, a theme object, Tailwind config, Sass variables — NEVER write a literal where a token exists. Look up the token; don't invent the value.

Every hardcoded color and spacing literal opts that element out of theming, rebrands, and dark mode, invisibly, until the day the system changes and it doesn't.

- Before styling anything, find how sibling components get their colors/spacing/type. The project's pattern (var(--token), theme(), tw classes, $vars) is the only sanctioned source for those values.
- Colors: never write hex/rgb/hsl literals when a palette exists. Can't find a token for the color you need? That's a question for the human ("closest token is --color-warning-600 — use it, or is this a new palette entry?"), not a license to inline `#e8a13c`.
- Spacing and sizing: stay on the scale. If the scale is 4-based, 9px is wrong on purpose-shaped feet; use the scale step (or the spacing token) even when the mock measures 9. Mock pixel values are renderings of tokens, not specs for literals.
- Type: font sizes, weights, and line heights come from the type scale/text styles, not from per-component numbers.
- Don't create private lookalike variables (`--my-button-blue: #3b82f6`) shadowing the system; that's a hardcode with a token costume.
- Semantic over raw where the system offers both: `--color-danger` survives a rebrand that `--red-500` usage may not.
- Exceptions exist (a one-off marketing page, a value with no plausible token) — mark them with a comment saying why, so they're findable and intentional.

**Red flags that you're about to violate this:**

- "I know the brand blue, I'll just write the hex."
- "9px of padding matches the mock exactly."
- "Finding the right token takes longer than typing the value."
- "I'll define my own variable for this color real quick."
- "It's one gray border, hardly worth a token."
- "The nearby file uses a hex literal, so that's the convention."

---

## Why It Works

1. **It mandates the lookup the AI skips.** The whole failure is that inventing a value is cheaper than discovering the token's name; making the sibling-component check a precondition flips the cost order.
2. **It routes the missing-token case to a human.** "No token fits" is the legitimate edge that otherwise justifies every hardcode; converting it into a question preserves the system instead of eroding it.
3. **It reframes mock measurements as token renderings.** "The mock says 9px" feels like fidelity to spec; the rule explains that the spec is the scale and the mock is its output, dissolving the strongest rationalization.
4. **It bans the lookalike-variable laundering.** Wrapping a literal in a private custom property satisfies a naive "use variables" rule while keeping every drawback; naming the move closes the loophole.

## Origin

A product spent a sprint shipping dark mode: tokens flipped cleanly, and then QA filed 40 screenshots of light-mode islands — buttons, badges, and borders that an assistant had styled with literal hex values over the preceding months, each individually approved because each individually looked right. The cleanup grep for hex literals in component styles returned 312 hits to manually triage. The team's retro added one line to their assistant instructions, which is approximately this one.
