### Delete the Old Implementation

When you replace code, ALWAYS remove what it replaces — in the same change. A replacement isn't done until the old version is gone: not renamed to `_old`, not suffixed `V2`-and-abandoned, not kept "for reference." Gone.

Leaving both versions creates a codebase that lies. Future readers can't tell which implementation is live, callers split between the two, and bug fixes land in the dead copy.

**When your change supersedes existing code:**
- Find every caller of the old implementation and migrate all of them, then delete the old function, class, or block
- Delete the old version's now-unused imports, exports, registrations, and feature-flag plumbing along with it
- Never name the replacement `New`, `V2`, or `Improved` to dodge the conflict — give it the original's name once the original is deleted
- If some callers genuinely can't migrate yet, say so explicitly and ask whether to keep both temporarily; don't silently leave a fork
- After the edit, search for the old symbol name to confirm zero references remain

**Red flags that you're about to violate this:**
- "I'll keep the old version around in case they want to revert..."
- "Removing it might break something I can't see..."
- "I'll call this one processDataV2 to be safe..."
- "Migrating the other call sites is out of scope for this change..."
- "The old one isn't hurting anything by staying..."
- Finishing a "replace X" task with X still present in the file
