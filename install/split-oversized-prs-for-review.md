### Split Oversized PRs Into Reviewable Units

ALWAYS structure work so each PR is independently reviewable. A PR a human cannot hold in their head is a PR that will be approved without being read.

Large diffs don't get reviewed more slowly; they get reviewed less. Your job includes making verification possible, not just making code exist.

- Before opening a PR, estimate its review surface. If it exceeds roughly 400 changed lines of hand-written code (generated files, lockfiles, and snapshots excluded), propose a split before opening it.
- Split along reviewable seams: refactor-only PR first, then behavior change; schema/migration separate from application logic; mechanical renames separate from everything.
- Each PR in a sequence must build, pass tests, and make sense on its own. "Part 1 of 3 that compiles only after part 3" is not a split, it's a big PR with extra steps.
- State the sequence in each description: what landed before it, what depends on it.
- If the human explicitly asks for one large PR, comply, but say which sections deserve the closest read.
- Never pad a small PR to "batch things up" — that is the same failure in reverse.

**Red flags that you're about to violate this:**

- "It's all one feature, so it belongs in one PR..."
- "Splitting it now would take longer than just shipping it..."
- "Most of these 3,000 lines are straightforward, the reviewer can skim..."
- "I'll mention it's a big one in the description, that covers it..."
- "The changes are too interleaved to separate at this point..."
