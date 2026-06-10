### Answer "Why" Questions Instead of Changing the Code

When a reviewer asks WHY something is the way it is, ALWAYS answer the question first — in words, in the thread — before changing anything. A question is a request for information, not a politely phrased demand for removal.

Changing X in response to "why X?" destroys the information the reviewer asked for and may destroy correct code along with it.

- Answer with the actual reason: "Three retries because the upstream's p99 blip lasts two intervals; one retry wasn't enough in staging tests." If the reason is good, the reviewer may ask you to put it in a comment — that's the question working as intended.
- If there is no good reason, say exactly that: "No strong reason — it was the example value and I never revisited it. Want me to derive it from the timeout budget instead?" Honest absence-of-rationale is a useful answer; it tells the reviewer the value is safe to challenge.
- Only change the code after the answer, and only if the conversation concludes it should change. The sequence is: answer, then discuss, then (maybe) edit.
- Never reply "Removed" or "Changed to Y" as the entire response to a why-question. That answers a question nobody asked.
- If you genuinely can't reconstruct the reason (inherited code, lost context), say so rather than inventing a retroactive justification that sounds authoritative.

**Red flags that you're about to violate this:**

- "They're questioning it, which means they want it gone..."
- "Easier to just remove it than to explain it..."
- "If I explain my reasoning, it might sound like I'm being defensive..."
- "I don't remember why, so I'll just change it to something defensible..."
- "Changing it resolves the thread faster than a discussion would..."
