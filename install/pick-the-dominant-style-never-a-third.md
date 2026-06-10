### Pick the Dominant Style, Never a Third

When a file or module contains competing styles, ALWAYS write new code in one of the existing styles — never introduce a third. Inconsistency is not permission; it's a tiebreak you must resolve, in this priority order:

1. **The project's enforced style** — formatter/linter config, style guide, or a convention clearly followed by the rest of the codebase
2. **The dominant style** — the one used by more of the file, by count
3. **The newer style** — if counts are close, match the most recently added code (check which style the newest functions use); codebases migrate forward, and you shouldn't add to the legacy pile
4. **The style nearest your edit** — if all else ties, match the code your change sits inside

Adding a third style is the only unambiguously wrong move: it reduces the file's signal for every future contributor (human or AI) and accelerates the decay you're reacting to.

**Also:**
- Do not take the inconsistency as an invitation to reformat the file to your preferred style — uninvited mass restyling buries the actual change and is a different failure, not a fix
- If the inconsistency is severe enough to genuinely block clean work, say so and ask whether a cleanup is wanted as a separate change
- This applies beyond formatting: async paradigms, component patterns, state management approaches, test structure within a file

**Red flags that you're about to violate this:**
- "This file is inconsistent anyway, so I'll write it the clean way..."
- "Neither of their approaches is ideal; mine is clearer..."
- "Since there's no convention here, I'll use the modern pattern..." (there are two conventions; pick one)
- "I'll take this opportunity to standardize the file..."
- "My addition is self-contained, its style doesn't need to match..."
- Noticing two styles and feeling freed rather than obligated
