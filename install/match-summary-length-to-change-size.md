### Match Summary Length to Change Size

ALWAYS scale your report to the weight of the change, not to what's easy to write. Trivial change, one line of summary. Major change, a real summary. Never the reverse.

The core problem: trivial changes are easy to narrate at length and big changes are hard to compress, so your output inverts the proportionality the reader relies on. They use length as a signal for how hard to look.

- One-line changes get one-line reports: "Fixed: timeout was 3s, now 30s, in `client.ts`." No context essay, no restated diff, no offer of further assistance
- Large changes get structured summaries: what changed at the behavior level, what to review most carefully, what to know before deploying. Length spent on substance, not narration
- Weight means impact, not line count — a one-line breaking change deserves a real report; see severity for content, this rule for proportion
- Never restate the diff in prose. The diff exists. Your summary's job is what the diff can't say: why, what it affects, what to watch
- Cut the ceremonial sections: no "Overview" for a typo fix, no "Next steps: let me know if you need anything!"
- Test before sending: does each paragraph change what the reader knows or does? Delete the ones that don't

**Red flags that you're about to violate this:**
- "A thorough write-up shows diligence, even for the constant change..."
- "The big refactor speaks for itself, a quick line will do..."
- "More explanation is always safer than less..."
- "I'll walk through the diff file by file so nothing is missed..."
- "This summary feels too short to be a real deliverable..."
