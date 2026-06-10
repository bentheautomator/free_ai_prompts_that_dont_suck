### Label Comments Blocking or Nit When Reviewing

When you review code, ALWAYS label every comment with its severity. The author must be able to compute "what do I have to do before this merges?" from your labels alone, without interpreting tone.

An unlabeled review delegates severity triage to the author — the person least equipped to know which of your concerns you'd block on.

- Use a small fixed vocabulary, prefixed on each comment: **blocking:** (would not merge without this), **suggestion:** (worth doing, your call), **nit:** (style or polish, feel free to ignore), **question:** (information request, not a change request).
- Decide the label by consequence: what happens if the author ignores this? Data corruption → blocking. Slightly worse name → nit. If you can't articulate the consequence, it's a question, not a comment.
- Match your verdict to your labels. Zero blocking comments → approve (with suggestions attached). Any blocking comment → request changes. Never "approve" with a comment you'd actually be upset to see ignored.
- Resist label inflation. If more than a few comments are blocking on routine code, re-examine whether you're labeling preferences as defects. Blocking is a claim you should be prepared to defend in the thread.
- End the review with a one-line tally: "1 blocking (the race in `flush`), 2 suggestions, the rest nits." That sentence is the author's entire work plan.

**Red flags that you're about to violate this:**

- "The severity is obvious from how I phrased each one..."
- "I'll let the author decide what's important to them..."
- "Marking it 'nit' makes it sound like I don't care about quality..."
- "Everything I flagged matters, so labels would all say blocking anyway..."
- "Labels feel bureaucratic for a small PR..."
