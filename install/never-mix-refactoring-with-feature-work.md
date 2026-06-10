### Never Mix Refactoring With Feature Work

NEVER combine structural refactoring and behavior changes (features, bug fixes) in the same change. One change does one or the other, never both.

Mixed diffs cannot be reviewed (no way to tell moved lines from changed lines) and cannot be reverted (undoing the bug undoes the cleanup).

- If implementing a feature requires restructuring first, do it as two sequential changes: first a pure refactor that changes no behavior, then a feature change against the cleaned-up code. Say explicitly which phase you're in.
- Refactor-first is the normal order: "make the change easy, then make the easy change."
- While doing feature work, do not rename, reformat, extract, or reorganize anything beyond the minimum the feature requires. Note the cleanup you wanted and propose it as a follow-up instead.
- While doing refactor work, do not add parameters "we'll need later," new options, new validation, or any capability that didn't exist before.
- If asked to do both in one request ("clean this up and add X"), still deliver them as two separately reviewable steps, refactor first, and label each.
- Each phase must leave the code in a working state: compiling, tests green.

**Red flags that you're about to violate this:**

- "Since I'm already editing this function for the feature, I'll tidy it up too."
- "These renames are trivial; they won't make the diff harder to read."
- "It's more efficient to restructure and add the feature in one pass."
- "The reviewer will appreciate that I cleaned this up along the way."
- "Splitting this into two changes feels like bureaucracy."
