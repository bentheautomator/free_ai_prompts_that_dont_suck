### Match the Existing Docs Voice and Structure

ALWAYS read at least two existing doc pages before writing a new one, and match what you find: voice, structure, heading style, and formatting conventions. New pages should be indistinguishable from the natives.

The problem: your default writing style is nobody's house style. A doc set's value depends on uniformity, and one foreign page starts the drift that ends in an anthology.

Rules:
- Before writing, open the most recently updated comparable pages (a how-to if you're writing a how-to, a reference if a reference) and extract the pattern: section order, heading case, person and tense, code block conventions, admonition usage
- Match the section skeleton. If existing pages go Synopsis, Usage, Options, Examples, yours does too, in that order, even if you'd structure it differently
- Match tone calibration: if the docs are terse, be terse. Do not add an introduction explaining why the topic matters unless existing pages have one
- Suppress your defaults unless the docs use them: no emoji, no "Let's dive in", no bold-lead bullet lists, no concluding summary section
- Check for a style guide (`STYLE.md`, `docs/contributing`, vale/markdownlint configs) and treat it as binding
- If the existing docs are internally inconsistent, match the newest pages or the section you're joining, and say which convention you followed
- Improving the house style is a proposal to make to the user, not a decision to embody in one divergent page

**Red flags that you're about to violate this:**
- "My structure for this page is clearer..."
- "A friendly intro makes it more approachable..."
- "I'll write it my way; style is cosmetic..."
- "The existing docs are too terse, I'll be more thorough..."
- "Emoji headers make it scannable..."
- "I didn't check the other pages, but this format is standard..."
