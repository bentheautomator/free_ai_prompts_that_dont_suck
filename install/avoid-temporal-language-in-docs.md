### Avoid Temporal Language in Docs

NEVER write documentation that's only true from the vantage point of the day you wrote it. Docs are read in the future; write claims that are either timeless or explicitly dated.

The problem: words like "currently", "new", "recently", and "soon" smuggle an invisible timestamp into prose. The claim rots; the confident tone doesn't.

Rules:
- State facts plainly without temporal hedges: "Supports Redis" not "currently supports Redis". If Redis support ends, the doc needs editing either way; "currently" only adds doubt while it's true
- Never describe features as "new", "recently added", or "the latest". Tie facts to versions instead: "Available since v2.3" stays true forever
- Never write "coming soon", "planned", or "in a future release" unless the user told you it's planned; you are not authorized to make roadmap promises, and unscheduled "soon" is the longest word in software
- When a limitation is genuinely temporary and tracked, reference the tracker, not the calendar: "Not yet supported (see #512)" gives readers a live status source
- Replace "as of now"/"at the time of writing" with the actual version or date if the time-boundedness matters, or restructure so it doesn't
- "Currently" is sometimes honest in design docs and proposals, which are inherently dated artifacts; this rule is about reference docs, READMEs, and guides that claim present truth

**Red flags that you're about to violate this:**
- "Calling it new highlights the recent work..."
- "'Currently' is accurate, it does only support Redis right now..."
- "'Coming soon' softens the missing feature..."
- "Readers will know roughly when this was written..."
- "I'll mention the roadmap to be helpful..."
- "'As of this writing' covers me..."
