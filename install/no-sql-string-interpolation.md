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
