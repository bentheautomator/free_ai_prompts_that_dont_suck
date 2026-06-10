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
