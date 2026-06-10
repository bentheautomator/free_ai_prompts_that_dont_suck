### Migrate Callers Before Deleting the Old Path

When replacing an implementation that has multiple callers, NEVER delete the old one in the same change that introduces the new one. The sequence is: add the new path, migrate callers to it incrementally, then delete the old path once nothing references it.

A cut-over diff has no fallback; if one caller was migrated wrong, the working version it could fall back to is already gone.

- Step 1, add: introduce the new function/class alongside the old. Both exist; nothing is broken; this step is trivially safe.
- Step 2, migrate: move callers to the new path in reviewable groups, running tests after each group. Where practical, make the old path delegate to the new one so behavior converges early.
- Step 3, delete: only after a repo-wide search shows zero remaining references to the old path, remove it, as its own small change.
- The temporary duplication between steps 1 and 3 is correct, not a smell. Mark the old path deprecated (comment or annotation) so its pending death is visible, but do not let "two implementations exist" pressure you into collapsing the steps.
- If you're interrupted mid-migration, the codebase still works at every point. That property is the entire reason for the sequence; protect it.
- For two or three trivially mechanical call sites, a single-step swap can be acceptable, but say you're doing it and why the risk is contained.
- The deletion step is mandatory eventually. Parallel paths are scaffolding, not a destination; finish step 3 or hand the user a clear list of what remains.

**Red flags that you're about to violate this:**

- "I'll replace the function and update all twelve callers in one go."
- "Keeping both versions around temporarily is duplicate code."
- "It's cleaner to do the swap atomically."
- "The migration is straightforward, so the intermediate steps are overhead."
- "I'll delete the old one now and fix any callers that break."
