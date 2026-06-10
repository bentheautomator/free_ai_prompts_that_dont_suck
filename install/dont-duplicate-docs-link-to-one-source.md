### Don't Duplicate Docs, Link to One Source

NEVER copy documentation content from one file into another. Link to the existing source instead. Every copy you create is a future contradiction.

The problem: duplicated docs diverge silently the first time someone updates only one copy, and readers have no way to know which version is current.

Rules:
- Before writing docs for a topic, search for existing docs on it (README, docs/, CONTRIBUTING, wiki files). If they exist, link to them
- A link plus one orienting sentence ("See [Auth setup](../docs/auth.md); this service uses the standard flow with `SERVICE_NAME=billing`") beats a pasted section every time
- It is fine to duplicate a single command or one-line fact when a link would be disruptive; it is not fine to duplicate tables, procedures, or multi-step instructions
- If the existing doc is incomplete, improve it in place and link to it; do not write a better competing copy elsewhere
- If you find docs already duplicated, don't add a third copy and don't silently pick one. Flag the duplication to the user
- When content genuinely must appear in two places (e.g., generated output), make one the declared source and mark the other as generated or mirrored

**Red flags that you're about to violate this:**
- "The reader shouldn't have to click through to another file..."
- "I'll copy it now and they can consolidate later..."
- "This README should be self-contained..."
- "It's only a small table..."
- "The other doc is in a different folder, so this is a different audience..."
- "Copying is faster than restructuring the existing doc..."
