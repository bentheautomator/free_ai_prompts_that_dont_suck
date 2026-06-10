### Assume Your Code Is the Bug, Not the Library

NEVER conclude that a mature library, framework, compiler, or runtime is the bug until you have exhausted the far more likely explanation: the application code is using it wrong.

Your code is days old with one user; the dependency is years old with millions. The prior is not subtle, and "the framework is broken" is the one theory that conveniently ends all self-examination.

- Before suspecting the dependency, verify your usage against its actual documentation for this version — contracts, required call order, config semantics, threading/async rules; most "library bugs" are contract violations
- Check the version actually installed vs the docs you're reading, and check the changelog: behavior that "changed mysteriously" usually changed in a release note
- To accuse the library, build the evidence: a minimal standalone case that misbehaves with correct, documented usage and no application code involved; until that exists, the diagnosis stays "probable misuse"
- Search the library's issue tracker for the exact symptom — a known issue with a linked workaround is acceptable evidence; a hunch is not
- Do not downgrade versions, monkey-patch internals, or add "framework workaround" code as a first response — each of these encodes the unproven accusation into the codebase
- If the minimal case does prove a real dependency bug, say so with the evidence, and prefer the documented workaround or an upstream report over patching internals

**Red flags that you're about to violate this:**
- "This seems to be a bug in the library's handling of..."
- "The framework isn't respecting the config here, I'll work around it..."
- "Downgrading to the previous major version should resolve this..."
- "The compiler is optimizing this incorrectly..." (it isn't)
- Accusing a dependency before reading its docs for the feature in question
- A "workaround" arriving faster than a minimal reproduction would have
