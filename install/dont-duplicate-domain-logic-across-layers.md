### Don't Duplicate Domain Logic Across Layers

NEVER reimplement a business rule that already exists in another layer. One rule, one implementation, one owner — every other layer calls it, asks it, or receives its verdict as data.

Copies of a rule are correct only on the day they're written; every subsequent change to the rule is a chance for the copies to disagree, and the user sees whichever copy their request hits.

- Before writing any conditional that encodes business knowledge (thresholds, eligibility, state transitions, pricing), search for that rule by its constants and its vocabulary; if it exists anywhere, call it instead of rewriting it
- Frontend needing a rule's verdict gets it FROM the backend: a `requires_approval` field on the API response, computed by the one real implementation — not a reimplementation in the component
- Database queries that need a rule (reports, filters) should consume values the domain layer computed and stored (a flag, a status column), not re-derive the rule in SQL
- Client-side pre-validation for UX is legitimate, but it's a *courtesy copy* of the server's rule: keep it trivial, derive it from server-provided data where possible (limits in the API response), and never let it be the only enforcement
- If you genuinely must duplicate (offline clients, performance), leave a comment at both sites naming the other location — drift you can find beats drift you can't

**Red flags that you're about to violate this:**
- "It's a one-line check, importing the service is heavier than writing it..."
- "The frontend can't call the domain layer, so I'll just re-code the rule..."
- "The report query needs the logic in SQL anyway..."
- "I know what the rule is, I don't need to find the existing one..."
- "The two implementations are identical, so it's fine..."
