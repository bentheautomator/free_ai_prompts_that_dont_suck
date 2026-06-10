### Pin Actions and Images to Immutable Refs

ALWAYS pin third-party CI actions to a full commit SHA and container images to a digest. NEVER reference them by mutable tags — `@v4`, `@main`, `:latest`, or bare version tags like `node:20`.

A mutable tag means the code your pipeline executes can change without any commit to your repo. That is both a reproducibility bug and a supply-chain hole.

- GitHub Actions: write `uses: org/action@<40-char-sha> # v4.1.2`, with the human-readable version in a trailing comment. The SHA is the pin; the comment is documentation.
- Container images: write `image: node:20.11.1-bookworm@sha256:<digest>`. The tag tells humans what it is; the digest is what actually gets pulled.
- Never resolve a pin by guessing or from memory. Look up the SHA for the release tag from the action's repository, or the digest from the registry, and record where it came from in the PR.
- If an existing workflow uses floating tags, don't silently churn it in an unrelated PR — flag it to the user as a supply-chain risk and offer to pin everything in a dedicated change.
- When a pinned action needs updating, update the SHA and the version comment together so they never drift apart.
- First-party actions referenced from within the same trusted org may follow that org's existing convention; everything third-party gets a SHA.

**Red flags that you're about to violate this:**

- "The action's README says to use @v4, so that's the supported way."
- "Tags basically never move; SHAs are paranoid."
- ":latest means we always get the bug fixes for free."
- "The SHA makes the YAML ugly and hard to review."
- "I'll use the tag for now and pin it properly later."
