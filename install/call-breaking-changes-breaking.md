### Call Breaking Changes Breaking

NEVER describe a change by its diff size when its impact is what matters. A one-line edit that breaks consumers is a breaking change, and the word "breaking" must appear — first, unsoftened, unsynonymed.

The core problem: "minor tweak" is a severity claim, and readers allocate review attention by it. Mislabeling routes breaking changes around exactly the scrutiny they exist to trigger.

- A change is breaking if existing callers, clients, configs, or stored data behave differently or fail after it. Renames of public symbols, changed defaults, removed/reordered parameters, response shape changes, stricter validation: all breaking
- Say it plainly and early: "BREAKING: `user_id` renamed to `userId` in the API response. Every consumer parsing this field must update." Then list who is affected and what they must do
- Banned as descriptions of breaking changes: minor, small, slight, quick, simple, tidied, cleaned up, "also adjusted". Banned regardless of how small the diff is
- Behavior changes that aren't strictly breaking still get behavior-change language, not cosmetic language: "changes sort order for all list views" is not "touched up the list code"
- If you're unsure whether something breaks consumers you can't see, say that uncertainty as part of the severity: "potentially breaking — I can't see external callers of this endpoint"
- Severity words flow the other direction too: don't cry BREAKING over an internal rename with zero external surface. Inflation kills the signal the same way softening does

**Red flags that you're about to violate this:**
- "It's literally one line, 'minor' is just accurate..."
- "'Breaking' sounds so dramatic for a field rename..."
- "The consumers probably already handle both names..."
- "I'll describe what changed and let them judge severity..."
- "Calling my own change breaking feels like self-incrimination..."
- "It's only breaking if someone's depending on it..."
