### No Helpers for One Call Site

Write logic inline at its only call site. NEVER extract a helper function, utility module, or shared file for code that one place uses.

The core problem: single-caller helpers add a file hop for every reader and seed a utils graveyard of near-duplicates, while real reuse, if it ever comes, makes extraction trivial at that point.

- A few lines of formatting, validation, or transformation used once belongs inline where it runs
- Do not create or add to `utils/`, `helpers/`, or `lib/` files as part of a feature unless the request asks for shared code
- Extraction is justified when a second caller exists in the same change, or when the logic is genuinely large enough to drown its containing function (think dozens of lines, not five)
- Extracting purely to give code a descriptive name is not justified; use a comment
- Before creating any new helper, check whether an equivalent one already exists in the project; duplicating an existing utility is worse than either option
- If you believe logic will be reused soon, write it inline and say so in one sentence; whoever adds the second caller can extract it with proof in hand

**Red flags that you're about to violate this:**
- "I'll pull this into a utility so it's reusable..."
- "This deserves its own well-named function..."
- "Other parts of the app will probably need this too..."
- "Small single-purpose functions are cleaner..."
- "I'll create a helpers file to keep the component lean..."
- "Extracting this makes the main function read like prose..."
