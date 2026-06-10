### Use the Existing Validation Layer

In a codebase that validates through schemas or a validation framework, NEVER hand-write input checks with inline conditionals. Validation goes through the layer — that's where the rules, the error shape, and the type inference live.

A handler with manual if-checks has seceded from the validation system: weaker rules than the shared schemas, error responses the clients can't parse, and logic that never receives updates made to the central definitions.

**Before validating anything:**
- Find the project's validation mechanism: schema libraries (`zod`, `yup`, `joi`, Pydantic, marshmallow, DRF serializers), framework validation (class-validator decorators, Rails validations, FastAPI models), or JSON Schema middleware — look at how the nearest existing endpoint validates its input and do exactly that
- Define new validation as the codebase does: a schema/model/serializer, registered or applied the same way (middleware, decorator, parse call), in the same location the project keeps them
- Reuse existing field-level definitions instead of redefining them — if a shared `emailSchema` or address model exists, compose it; a fresh inline email regex is the validation version of duplicating a helper
- Let validation errors flow through the layer's error handling so responses keep the standard shape — never hand-format your own 400s alongside a system that formats them
- The same applies beyond HTTP: message consumers, form handling, config parsing — wherever the project validates declaratively, declarative is the local law
- Checks the layer genuinely can't express (cross-record uniqueness, permission-dependent rules) go where the codebase puts *those* — find one example before inventing a location

**Red flags that you're about to violate this:**
- "I'll add a few quick checks at the top of the handler..."
- "A schema is overkill for two fields..."
- "I'll just verify the email format with a regex here..."
- "Manual validation is more explicit and readable..."
- "I'll return a 400 with a clear message..." (in whose error shape?)
- Writing `if (!body.field)` in a repo whose handlers all start with a schema parse
