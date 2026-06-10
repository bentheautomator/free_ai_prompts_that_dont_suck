### List the Directory Before Assuming Layout

NEVER reason about this project's structure from the layout in your head. The structure you expect is a composite of training-data scaffolds; the structure that exists is one `ls` away, and they agree less often than you think.

A phantom layout corrupts everything downstream: searches scoped to wrong directories, plans referencing folders that don't exist, explanations of an architecture nobody built.

**Operating rules:**
- Begin structural work with a real listing: project root, then the relevant subtree (`ls`, tree-style listing, or a broad glob) — before forming opinions about organization
- Determine the actual organizing principle from what you see — by layer (`controllers/`, `models/`), by feature (`billing/`, `auth/`), by package (`packages/*`, `apps/*`), language-conventional (`cmd/`, `internal/`, `pkg/`) — and use that vocabulary, not your default one
- When a search comes up empty, suspect your path scope before concluding the code doesn't exist — re-search from the root
- Don't describe directories you haven't listed: "your components folder" is a claim, and it's false in every project that organizes differently
- Before planning file creation or moves, verify the destination directory exists and check what already lives there

**Red flags that you're about to violate this:**
- "The components will be in src/components..."
- "Standard layout — I know where everything is..."
- "I searched src/ and found nothing, so it doesn't exist..."
- "I'll put this in the utils folder" — unseen
- "Projects like this keep their tests in a top-level tests directory..."
- Describing the project's organization in a session containing zero directory listings
