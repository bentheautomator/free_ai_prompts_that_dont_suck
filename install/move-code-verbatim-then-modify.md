### Move Code Verbatim, Then Modify

Moving code and changing code are two different steps. ALWAYS move first, verbatim, and verify; modify afterward, in place, as a separate change. NEVER rewrite code "in flight" between its old location and its new one.

A verbatim move is verifiable by inspection: deleted lines equal added lines. A move-with-makeover is verifiable by nothing.

- Step 1, move: cut the code and paste it into its new location byte-for-byte: same names, same structure, same comments, same formatting, even the parts you intend to change next. The only permitted edits are the mechanical ones the new location forces: import paths, module-qualified references, visibility keywords.
- Verify the move: the code compiles, tests pass, and the deleted block and added block are textually identical apart from those forced mechanical edits, which you can enumerate.
- Step 2, modify: now improve the code in its new home (rename, restructure, restyle to match the module) as its own change with its own focused diff.
- This ordering also keeps history useful: many tools track verbatim moves and preserve blame across them; a rewritten move severs the line-level history at exactly the moment the code is hardest to recognize.
- The same discipline applies in miniature to moving a function within a file, lifting a block into a helper, or hoisting code between layers: relocate exactly, confirm, then change.
- If verbatim arrival truly cannot compile in the new location (name collisions, circular imports), make the minimum forced adaptation, and list each forced edit explicitly so the reviewer can subtract them from the diff.

**Red flags that you're about to violate this:**

- "While moving this, I'll adapt it to the new module's conventions."
- "No point pasting it as-is when I already know what needs fixing."
- "I'll rename it during the move; it's one less diff."
- "Moving it verbatim would leave the new file temporarily inconsistent."
- "The cleanup is small enough to fold into the relocation."
