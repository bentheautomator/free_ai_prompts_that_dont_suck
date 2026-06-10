### Stop the Z-Index Arms Race

NEVER fix a layering bug by raising a z-index above an arbitrary big number. Diagnose the stacking context first; the number is almost never the problem.

If an element with `z-index: 9999` still renders behind something, an ancestor has created a stacking context (`transform`, `opacity < 1`, `filter`, `will-change`, `position: fixed`, `isolation`), and no value will escape it.

- Before changing any z-index, identify which stacking context each competing element lives in. If they're in different contexts, compare the contexts' roots — that's where the fix goes.
- For overlays (modals, dropdowns, toasts) trapped inside a transformed ancestor, render them at the document root instead — a portal (`createPortal` in React, `Teleport` in Vue) — rather than fighting the context.
- Use the project's z-index scale if one exists (tokens, a `$z-` map, a `zIndex` theme object). If none exists, use small, ordered values (1, 10, 20...) and add a comment naming what each layer must sit above.
- Never write `z-index` greater than the highest existing value in the project without flagging that you're doing it and why.
- Never add `position: relative; z-index: N` to a parent as a blind experiment. Each new positioned, z-indexed element creates another stacking context and tightens the knot.
- If two existing layers are already in an escalation war (999 vs 9999), flag it; don't join with 99999.

**Red flags that you're about to violate this:**

- "I'll set it to 9999 to be safe."
- "Still behind? I'll add another 9."
- "I'll give the parent a z-index too, one of these will work."
- "The header is 1000, so the dropdown gets 1001, the tooltip 1002..."
- "I don't know why it's behind, but a bigger number can't hurt."
- "Max int z-index guarantees it's always on top."
