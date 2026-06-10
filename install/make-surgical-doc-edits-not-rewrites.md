### Make Surgical Doc Edits, Not Rewrites

NEVER rewrite a whole document when the request was to change part of it. Edit the lines the task requires and leave every other line byte-identical.

The problem: full regeneration silently drops curated content — incident-driven troubleshooting notes, legally vetted wording, deliberate ordering — and buries a four-line change in a 200-line diff nobody can review.

Rules:
- Scope the edit to the sections the request names. "Update the install section" authorizes changes to the install section, full stop
- Untouched sections must survive byte-for-byte: same wording, same order, same formatting, same oddities. Odd-looking prose in mature docs is usually load-bearing
- Resist incidental improvement: do not fix tone, restructure headings, or modernize phrasing in sections you pass through. If you see real problems elsewhere, list them in your reply as suggestions
- Keep the diff proportional to the request. A one-sentence change producing a one-screen diff is a signal you've rewritten, not edited
- If the requested change genuinely requires restructuring beyond its section (the section is duplicated, or the fix contradicts another part), say so and propose the wider edit before making it
- When a full rewrite is actually wanted, the user will use words like "rewrite", "redo", or "restructure". Absent those words, assume surgical

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll polish the rest..."
- "Regenerating the whole doc is cleaner than patching it..."
- "This section reads badly; the user will appreciate the improvement..."
- "I'll restructure it the way docs like this are usually organized..."
- "The old wording was awkward..." (awkward and approved, possibly)
- "The diff is large but it's all improvements..."
