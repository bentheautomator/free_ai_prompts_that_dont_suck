---
title: Use the Existing Validation Layer
slug: use-the-existing-validation-layer
category: code-quality
tags: [universal, validation, patterns]
works_with: all
severity: high
one_liner: "AI writing manual if-checks in codebases that validate through schemas"
---

# Use the Existing Validation Layer

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from hand-writing input checks in projects where validation flows through a schema layer.

**[Copy-paste ready version](../../install/use-the-existing-validation-layer.md)** — just the instruction block, no explanation.

## The Problem

Every endpoint in the service validates its input with a `zod` schema — or Pydantic models, or Joi, or DRF serializers, or JSON Schema middleware. Validation is declarative, centralized, and produces a consistent error shape that the frontend knows how to render. Then an AI writes a new handler and validates the old-fashioned way: `if (!req.body.email || !req.body.email.includes('@')) return res.status(400).send('invalid email')`. A stack of manual if-checks, inline, with hand-written error strings.

The handler "validates," so the task looks done — but it has seceded from the validation system. Its error responses don't match the shape the schema layer produces, so client-side form handling breaks on exactly this endpoint. Its rules are weaker than the shared schemas (the project's email schema also normalizes case and checks length; the if-check doesn't), so this endpoint accepts what every other endpoint rejects. Type inference that schemas provide downstream is gone, so the handler body works with `any`-shaped input. And the rules now live where no one will update them: when the team tightens the shared email schema, this handler keeps its 2-line opinion forever. The AI does this because if-statement validation is the dominant form in training data — schema layers are a per-project architecture, and the model writes the universal pattern instead of the local one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It identifies the training-data mismatch.** Inline if-checks are the universal validation idiom in tutorials; schema layers are local architecture. Naming why the model defaults wrong makes "look at the neighboring endpoint first" feel necessary instead of optional.

2. **It defines secession, not just inconsistency.** The manual checks *work*, which is why the AI considers them done. Spelling out what's lost — shared rule updates, error shape, type inference — shows the if-stack is behaviorally weaker, not just stylistically off.

3. **It extends reuse down to the field level.** An AI using the schema library can still inline a fresh email regex inside it. Requiring composition of existing field definitions closes the small-scale version of the same fork.

4. **It routes the genuinely-hard cases.** Some checks don't fit schemas, and that's the loophole through which whole handlers escape the layer. Sending those checks to "where the codebase puts those" keeps the exception from swallowing the rule.

## Origin

A signup-adjacent endpoint went out with hand-rolled validation in a Pydantic-everywhere service. The shared `EmailStr`-based model lowercased addresses; the manual check didn't. Users who registered as `Name@domain.com` through the new endpoint could never log in again — login normalized, signup hadn't — and the resulting duplicate-account mess produced weeks of support tickets and a data-cleanup script with seventeen edge cases. The fix was four lines: deleting the if-checks and using the model that had existed all along.
