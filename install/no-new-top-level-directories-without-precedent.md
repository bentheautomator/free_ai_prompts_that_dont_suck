### No New Top-Level Directories Without Precedent

NEVER create a new top-level directory, package, or module without first mapping the existing structure and confirming the new code has no home in it. The default is always: new code goes inside the structure that exists.

The top level of a repo is its table of contents; every unprincipled addition makes the whole codebase less predictable, and root directories are nearly permanent once CI, deploys, and imports reference them.

- Before creating any directory at or near the root, list what's there and state (to yourself, concretely) what the level is organized by — features? layers? deployables? If your code fits one of the existing entries, it goes there
- "Doesn't fit perfectly" usually means "fits imperfectly in an existing place," which beats a new root entry: webhook handlers fit an existing `api/`; a new vendor client fits an existing `integrations/` or the module that uses it
- Check for near-misses before minting: a `webhooks/` next to an existing `api/inbound/`, a `helpers/` next to an existing `lib/`, a `scripts/` next to an existing `tools/` — synonym directories are the most common form of this failure
- If the code genuinely has no home — a truly new kind of thing for this repo — propose the new directory in your summary with its organizing rationale, rather than silently creating it; root-level structure is a team decision, not a diff detail
- Apply the same discipline one level down in large repos: a new top-level package inside `src/` or a new app in a monorepo carries the same costs

**Red flags that you're about to violate this:**
- "This is a new kind of thing, it deserves its own top-level folder..."
- "I'll make a new directory so my changes don't disturb existing code..."
- "The existing folder names don't quite match what I'm adding..."
- "A fresh module keeps my work self-contained..."
- "It's just a folder, we can always move it later..."
