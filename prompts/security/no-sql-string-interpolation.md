---
title: Never String-Interpolate User Input Into SQL
slug: no-sql-string-interpolation
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI building SQL with f-strings or template literals while prototyping"
---

# Never String-Interpolate User Input Into SQL

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from concatenating user input into SQL queries instead of using parameters.

**[Copy-paste ready version](../../install/no-sql-string-interpolation.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "add a search endpoint" and there's a decent chance you get `f"SELECT * FROM users WHERE name = '{name}'"` or `` `SELECT * FROM orders WHERE id = ${req.params.id}` ``. It runs, it returns rows, the demo works. It is also SQL injection, the vulnerability that has topped every web security list since before most frameworks existed. One `' OR 1=1 --` in a query string and your WHERE clause is decorative.

AI assistants produce this because interpolated SQL is shorter, reads naturally, and dominates tutorials and Stack Overflow snippets in the training data. The rationalization is always the same: "this is just a prototype, I'll parameterize it later." But prototype endpoints become production endpoints by the boring process of nobody ever rewriting them. The interpolation also tends to spread, because the next query in the file copies the style of the first.

The fix costs nothing. Every database driver in every mainstream language has supported parameterized queries for decades. There is no performance argument, no readability argument, and no "it's internal" argument that survives contact with an attacker.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never String-Interpolate User Input Into SQL

NEVER build SQL queries by concatenating or interpolating values into the query string. ALWAYS use parameterized queries or an ORM/query builder. This applies to prototypes, scripts, internal tools, and "temporary" code equally.

String-built SQL is SQL injection. There is no safe amount of it, and escaping by hand does not count as safe.

- Do not write `f"... WHERE id = {x}"`, `"... " + x`, `` `... ${x}` ``, `%` formatting, or `.format()` into any SQL string. This includes values that "come from our own frontend" — the frontend is not a trust boundary.
- Use placeholders: `cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))`, `db.query("... WHERE id = $1", [id])`, prepared statements in Java/Go, bound parameters everywhere else.
- Identifiers (table/column names, ORDER BY fields) cannot be parameterized: validate them against a hardcoded allowlist, never pass them through.
- For dynamic filters, build the clause structure in code and bind every value; never splice user input into the clause text.
- LIKE patterns: bind the parameter and escape `%`/`_` in the value, not in the query string.
- If you find existing interpolated SQL while editing a file, flag it to the user even if it is not the code you were asked to change.

**Red flags that you're about to violate this:**
- "This is just a prototype, parameterization can come later..."
- "The value is an integer from our own code, it can't contain SQL..."
- "I'll sanitize the input with a regex first, so interpolation is fine..."
- "This is an internal admin tool, only employees use it..."
- "The ORM makes this query awkward, raw SQL is cleaner here..."
- "I escaped the quotes manually, so it's safe..."

---

## Why It Works

1. **It kills the "prototype" loophole by name.** The AI's strongest rationalization is temporal: insecure now, secure later. Stating that prototypes and temporary code are covered removes the deferral option entirely.

2. **It enumerates the interpolation syntaxes.** f-strings, template literals, `.format()`, `+` concatenation — the AI pattern-matches on specific tokens better than on the abstract concept "dynamic SQL."

3. **It covers the identifier edge case.** "But you can't parameterize a column name" is the loophole AIs use to justify interpolating everything in a dynamic-sort query. Giving the allowlist answer closes it.

4. **It makes the secure version concrete.** A rule plus a working `cursor.execute` example means the AI never has to choose between "secure" and "code that I know compiles."

## Origin

A team asked an assistant to add filtering to an internal reporting endpoint. The assistant generated a query with the filter value interpolated directly into the WHERE clause, noting in its summary that it could "harden this later if needed." The endpoint was internal right up until it was included in a partner-facing API gateway, where a pentester dumped the user table with a single quoted parameter. The remediation diff replaced one f-string with one bound parameter.
