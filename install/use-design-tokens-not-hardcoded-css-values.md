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
