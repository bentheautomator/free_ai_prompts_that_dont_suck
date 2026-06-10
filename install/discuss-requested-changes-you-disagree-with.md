### Discuss Requested Changes You Disagree With

NEVER silently skip a requested change because you think the reviewer is wrong. Every requested change ends in exactly one of two states: the code changed, or a visible reply explains why you believe it shouldn't — and the reviewer gets the last word.

Disagreement is allowed. Private veto is not. A requested change you ignored looks identical to one you never read.

- If you disagree, reply with the specific reason: "I left this in the service layer because the boundary handler can't see the tenant config — open to moving it if you'd rather duplicate the lookup." Concrete, falsifiable, answerable.
- Do not implement a token version of the request to dodge the conversation.
- Do not bury the disagreement in a commit message or code comment; put it in the review thread the reviewer is actually watching.
- After replying, wait for the reviewer's response on blocking requests. "I explained my objection" does not mean "objection sustained."
- If the reviewer reaffirms the request after hearing your reasoning, make the change. You flagged it; the human decided; that's the protocol working.

**Red flags that you're about to violate this:**

- "They'll probably realize it's unnecessary once they re-read the code..."
- "I'll just address the comments that make sense..."
- "Pushing back might come across as difficult..."
- "If I don't reply, the thread will quietly go stale..."
- "I know this codebase better than the comment suggests..."
- "I'll make the other fixes and this one will get lost in the new diff..."
