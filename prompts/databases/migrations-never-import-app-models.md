---
title: Migrations Never Import App Models
slug: migrations-never-import-app-models
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: medium
one_liner: "Migrations that import live application models and break as the app evolves"
---

# Migrations Never Import App Models

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents migrations that depend on application models, which breaks them the moment the models change.

**[Copy-paste ready version](../../install/migrations-never-import-app-models.md)** — just the instruction block, no explanation.

## The Problem

A data migration needs to touch rows, and the AI already knows a lovely API for touching rows: the application's models. So the migration does `from app.models import User` and iterates `User.objects.all()`, calling `user.recalculate_score()`. It works today. Six months later someone renames the model, deletes that method, or adds a validation requiring a field that didn't exist when this migration was written, and now `migrate` crashes on a fresh database, on the CI schema build, on the new developer's first day. The migration didn't change; the world it imported did.

The mismatch is temporal. A migration is frozen at the moment of its creation; it must run correctly forever, against the schema as it existed *at that point in history*. The live model describes the schema as it exists *now*. Importing now-code into then-context works only while the two happen to coincide, which is to say, only near the moment the migration was written, which is the only time anyone tests it. Model-level side effects make it worse: validations, default scopes, and callbacks fire during the migration's iteration, doing things (sending emails, touching other tables) that nobody expects from `migrate`.

Frameworks that thought hard about this give you the answer: Django's `apps.get_model()` hands you a historical model matching the migration's point in time; everywhere else, raw SQL inside the migration is frozen, dependency-free, and honest.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It names the temporal mismatch.** "Frozen migration, moving app" is the mechanism the AI doesn't model; once stated, importing now-code into a then-context is visibly unsound rather than conveniently DRY.

2. **It kills the "runs once" rationalization with facts.** Migrations re-run constantly, every fresh database, every CI build, every new environment, so the premise under "then it doesn't matter" is simply false, and saying so removes the rule's biggest leak.

3. **It channels the convenience.** Historical models and inline stubs give the AI most of the ergonomics it wanted from the import, making compliance cheap instead of a raw-SQL chore it'll route around.

## Origin

A data migration used the live model to backfill a flag, including its `before_save` callback, which at the time was harmless. A year on, that callback had grown an external API call. A new region spin-up ran the full migration history against the provider's API, generating thousands of junk requests and failing the build partway when the API rate-limited, leaving a half-migrated schema. The fix was converting a four-line model loop into three lines of SQL, twelve months too late.
