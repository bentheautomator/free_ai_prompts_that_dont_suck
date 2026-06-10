### Adapt Every Line You Copy

When you base new code on an existing block, ALWAYS adapt every line — not just the lines that obviously mention the old context. Copying a pattern is good practice; half-adapting it produces code that's still partially wired to the original.

The lines you'll miss are the ones that don't look like code: strings, labels, keys, scopes. They're also the ones where a leftover does the most damage.

**After copying or modeling on existing code, audit the entire block for context leftovers:**
- Log messages and error messages still describing the original operation
- Cache keys, metric names, event names, queue names, and feature-flag keys still using the original's prefix — leftover cache keys mean serving the wrong data
- Permission scopes, role checks, and rate-limit buckets still referencing the original resource
- Comments explaining the original's logic, including doc comments and parameter descriptions
- Variable names, test descriptions, and fixture data that narrate the old context
- Copied edge-case handling that doesn't apply (or applies differently) to the new context — adaptation includes deleting what doesn't transfer
- Final check: search the new block for the original's key terms (e.g., grep your new export handler for "import"); every hit is either justified or a bug

**Red flags that you're about to violate this:**
- "I'll copy the existing handler and tweak it..."
- "Renamed the function and route — that's the substantive part..."
- "The log messages are close enough..."
- "The middle section is identical boilerplate, no changes needed there..." (boilerplate with the old name in it)
- "I've changed all the references..." (without searching for the old term)
- Presenting cloned code without having grepped it for the source's vocabulary
