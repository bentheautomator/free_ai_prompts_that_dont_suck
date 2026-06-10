### Verify Doc Code Examples Actually Run

NEVER put a code example in documentation that you haven't checked against the real code. Every example is a claim that "this exact text works" — treat it with the same rigor as code you ship.

The core problem: examples are generated from how APIs usually look, not how this one actually looks, and nothing automated catches the difference.

Rules:
- Before writing an example, read the actual function signature, the actual export, the actual import path. Don't write the call from memory
- If the project has runnable doc tests (doctest, mdbook test, examples/ directory in CI), put the example where it gets executed
- If it can't be executed, verify it manually: do the imports resolve, do the names exist, do the argument types match, does the shown output match what the code returns
- When editing code that an existing doc example uses, update the example in the same change — search the docs for the old names
- Copy real working code into examples and trim it down; don't compose examples from scratch and hope
- Show real output, not invented output. If the example prints something, run it or trace it

**Red flags that you're about to violate this:**
- "This is how this kind of API usually works..."
- "It's just an illustrative snippet, it doesn't need to be exact..."
- "The reader will adapt it to their setup anyway..."
- "Checking the actual signature is overkill for a doc example..."
- "I'll write the output it probably produces..."
- "The old example was probably correct, I'll extend it..."
