### Never Key React Lists by Index

NEVER use the array index as a `key` for list items that can reorder, filter, insert, or delete. Key by a stable identity from the data itself.

The key tells React which component instance owns which data across renders. Index keys mean "position is identity," so any reshape of the array reassigns every row's state — checkboxes, inputs, expansion — to the wrong record.

- Use the data's own id: `key={item.id}`, a database key, a slug, a unique field. This is the answer in roughly all cases.
- No id on the data? Look harder first (a compound of stable fields is fine: `key={`${user.id}-${role}`}`). If the data truly has no identity, generate one when the item is created — `crypto.randomUUID()` at creation/fetch time, stored on the item — never during render, and never `key={Math.random()}` (that remounts every row every render).
- Index keys are acceptable only when all of these hold: the list never reorders or filters, items are never inserted except at the end, never deleted, and rows hold no state. Static, hardcoded lists qualify. If you claim this exception, you are asserting all four — say so in a comment.
- Silencing the missing-key warning is not the goal. `key={index}` and `key={Math.random()}` both silence it while making behavior worse than the warning.
- When you encounter existing `key={index}` on a mutable list while editing, flag it; bugs from it are already latent.

**Red flags that you're about to violate this:**

- "map gives me the index right there, that's my key."
- "This makes the React warning go away, done."
- "The list probably won't be reordered."
- "There's no id field, so index is my only option."
- "Math.random() guarantees uniqueness."
- "It renders correctly, the key choice clearly works."
