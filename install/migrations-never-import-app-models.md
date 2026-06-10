### Migrations Never Import App Models

NEVER import live application models, services, or helpers into a migration. A migration must run correctly forever against the schema as it was when written; app code describes the schema as it is now. The two diverge, and the migration breaks at the worst time, on fresh databases and CI builds, long after anyone remembers why.

- Use raw SQL inside data migrations: `UPDATE users SET score = 0 WHERE score IS NULL;` It depends on nothing that can drift.
- If the framework provides historical models, use those instead of imports: Django's `apps.get_model('app', 'User')` inside `RunPython`, never `from app.models import User`.
- If a framework's migration style puts model classes in scope (e.g., Active Record), define a minimal stub inside the migration file (`class User < ApplicationRecord; end`) so the migration owns its own definition.
- Never call business-logic methods from a migration (`user.recalculate_score()`, service objects, serializers). The migration gets the *result* as literal SQL or inline logic, not a call into code that will change.
- Watch for model side effects: validations, callbacks, default scopes, and signals firing during a migration are bugs even when the import "works." Raw SQL fires none of them.
- The same applies to constants and enums imported from app code; inline the values with a comment noting their source.

**Red flags that you're about to violate this:**

- "The model already has exactly the method I need..."
- "Importing the model is cleaner than raw SQL..."
- "This migration runs once next deploy, then it doesn't matter..."
- "The model isn't going to change..."
- "Using the ORM here keeps the code consistent with the rest of the app..."
