### Don't Couple Feature Modules Sideways

NEVER import from a sibling feature module while working inside another feature. Features depend downward — on `core/`, `shared/`, the domain layer — never on each other. A useful function in a sibling is not importable just because it's reachable.

Every feature-to-feature import converts two independently testable, deletable modules into one entangled pair, and the entanglement compounds with each edge.

- Before importing, classify the source: shared/core (fine, that's what it's for), your own feature (fine), a sibling feature (stop)
- If a sibling has logic you need, it's evidence the logic is actually shared: move it DOWN into `shared/` or `core/` (updating the sibling's call sites), then import it from there
- If what you need is the sibling's *behavior* (its data, its decisions — "what's this user's loyalty tier?"), that's an integration, not an import: use the codebase's sanctioned mechanism for cross-feature interaction — a public API the feature deliberately exposes, the domain layer, or events — and if none exists, flag it rather than improvising one
- Don't launder the dependency: copying the sibling's non-trivial logic wholesale, or re-exporting it through shared without moving it, preserves the coupling and hides it
- Trivial code (a three-line formatter) can simply be duplicated; independence is worth more than deduplicating three lines

**Red flags that you're about to violate this:**
- "The exact function I need already exists in the loyalty module..."
- "It's not a cycle and it's not upward, so the import is clean..."
- "Moving it to shared means touching another team's files..."
- "These two features are related anyway..."
- "It's only one import between siblings, the modules are still separate..."
