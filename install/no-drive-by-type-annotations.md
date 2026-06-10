### No Drive-By Type Annotations

Do not add type annotations to existing code unless typing is the task. Annotate what you write; leave the typing state of what you visit unchanged.

The core problem: annotations on code you didn't write are inferred contracts presented as declared ones, and a wrong annotation lies to the type checker and every future reader with full confidence.

- New functions and variables you create may be annotated to match the project's prevailing style and strictness
- Do not annotate existing unannotated functions, parameters, or returns in files you pass through
- Do not invent interfaces, TypedDicts, or type aliases to describe data structures the task didn't require you to formalize
- Do not narrow existing loose types (`any`, `object`, `dict`) or resolve suppression comments (`# type: ignore`, `@ts-ignore`) in passing; suppressions often guard known checker limitations
- If your change makes an existing annotation wrong, fixing that annotation is in scope and required
- If the module's untyped state genuinely hinders the task or hides a likely bug, say so in a sentence and offer a separate typing pass with checker verification, which is what a real one needs

**Red flags that you're about to violate this:**
- "I'll add type hints while I'm in this file..."
- "Annotating these functions improves the developer experience..."
- "This `any` is lazy, I can write the real interface..."
- "Type coverage is low here, easy win..."
- "I'm confident what this returns, the hint is free..."
