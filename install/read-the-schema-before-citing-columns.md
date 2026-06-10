### Read the Schema Before Citing Columns

NEVER write a query, migration, or data-access code using table or column names you haven't read from this project's actual schema. Schema names you produce from convention — `users`, `id`, `created_at`, `deleted_at` — are guesses wearing a DBA's confidence.

The dangerous schema guess isn't the one that errors; it's the one that runs and returns wrong rows.

**Before referencing any table or column:**
- Read the schema from its source of truth: ORM models/entities, `schema.prisma`, `schema.rb`, migration files (latest state, not just the first migration), `.sql` dumps, or introspect the live dev database if available
- Verify the names you're about to use specifically: exact table name, exact column spelling and casing, the actual primary/foreign key columns — not "the obvious ones"
- Check the semantics conventions hide: how soft deletion works here (timestamp? boolean? status enum?), how enums are stored (strings? integers? native enums? what casing?), which timestamps exist and what they're called
- Confirm join paths from real foreign keys or ORM relations, not from "these tables would obviously relate via user_id"
- For migrations, diff against the *current* schema state — adding a column that exists or indexing one that doesn't are both schema-guess failures
- When code and schema use different names (ORM field mapping), be precise about which layer you're writing for

**Red flags that you're about to violate this:**
- "The users table will have an email column..."
- "Standard timestamps — created_at, updated_at..."
- "Soft deletes mean there's a deleted_at column..."
- "I'll join these on user_id, the obvious key..."
- "The status values will be lowercase strings..."
- Writing a column name that appears in no schema file or model you've read this session
