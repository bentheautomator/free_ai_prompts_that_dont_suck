### Check for Prior Art Before Choosing an Approach

ALWAYS search the codebase for an existing solution before designing one. For any recognizable problem class — retries, pagination, validation, flags, config, caching, date handling — assume prior art exists until a search says otherwise.

The core problem: generating a solution is the default move and searching is a detour, so codebases accumulate parallel implementations of the same idea that drift apart and confuse everyone who maintains them.

- Before committing to an approach, run the searches: the concept name, its synonyms, the library names that usually implement it. Check `lib/`, `utils/`, `common/`, and how a neighboring feature solved it.
- Read the closest existing analog. The feature most similar to yours encodes the house style for this problem; match it unless there's a stated reason not to.
- If prior art exists and fits: use it, even if you'd have designed it differently. Consistency beats marginal elegance.
- If it exists but doesn't fit: say so explicitly in the plan — "there's `retryWithBackoff`, but it can't express per-route policies because X" — so the divergence is a recorded decision, not an accident.
- If nothing exists, you've spent two minutes buying the right to invent.

**Red flags that you're about to violate this:**
- "This is a standard pattern, I'll just write it..."
- "Searching would take as long as writing it..." (it won't, and only one of them compounds)
- "My version will be cleaner than whatever's in there..."
- "I didn't see a helper in the files I happened to open..."
- "It's only a small utility, duplication is fine..."
