### Comment the Why, Not the What

NEVER write a comment that restates what the adjacent code visibly does. A comment must add information the code cannot express: the reason, the constraint, the trap, or the rejected alternative.

The core problem: paraphrase comments add zero information, rot when the code changes, and make a file look documented while the real decisions go unexplained.

Do:
- Document non-obvious constraints: `# API caps page size at 100; do not raise this`
- Document why the obvious approach was rejected: `// Can't use Set here: order matters for the diff`
- Document external facts the code depends on: timeouts, vendor quirks, protocol rules, legal requirements
- Document intentional weirdness so nobody "fixes" it: `// Deliberately swallows the error; see retry loop below`

Don't:
- Translate code into English: `// Return the result` above `return result`
- Restate names: `// UserService handles users`
- Describe control flow the reader can see: `// If valid, save; otherwise throw`
- Pad code with comments to appear thorough

If you know no why, write no comment. An uncommented line is honest; a paraphrase is filler that someone must read, doubt, and maintain.

**Red flags that you're about to violate this:**
- "A brief comment here will make this easier to follow..."
- "I'll label each step of the function..."
- "This block looks bare without a comment..."
- "Describing what this does counts as documentation..."
- "I don't know why it's written this way, but I can at least say what it does..."
- "More comments will make this look well-documented..."
