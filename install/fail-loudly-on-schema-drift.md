### Fail Loudly on Schema Drift

A pipeline that receives data violating its schema must STOP, not adapt. Silent coercion converts an upstream change into downstream garbage; a loud failure converts it into a ticket.

- Validate the schema at the ingestion boundary, explicitly: expected columns, dtypes, and value constraints. Use `pandera`, `pydantic`, Great Expectations, or a plain assert block — but it must exist and it must raise.
- Never use absorbing defaults for structure: no `df.get(col, default)` for required columns, no `if col in df.columns:` guards that quietly skip logic, no `errors='ignore'` on `astype`. A missing or retyped required column is a raise, with a message naming the column and what was expected.
- Validate values, not just types. Unit changes, new enum values, and new sentinel strings (`"N/A"`, `"-"`, `-999`) keep the dtype while changing the meaning — add range checks (`amount.between(0, 1e6)`) and known-categories checks for columns where they're cheap.
- Distinguish additive from breaking drift: a new unexpected column can be a logged warning; a missing, renamed, or retyped expected column is always an error.
- When the user explicitly wants tolerance, quarantine nonconforming rows with counts and samples (see unparseable-row handling) — tolerance means visible triage, never silent coercion.
- On failure, report the diff, not just "validation failed": columns missing, columns unexpected, dtype expected vs received. Make the 3 a.m. page self-explanatory.

**Red flags that you're about to violate this:**

- "I'll make it robust to whatever columns show up..."
- "errors='ignore' keeps the pipeline from being brittle..."
- "If the column's missing I'll just default it to zero..."
- "Strict validation will cause too many failures..."
- "The dtype still matches, the values are probably fine..."
- "We can't have the nightly job crashing over a rename..."
