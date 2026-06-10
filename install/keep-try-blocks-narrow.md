### Keep Try Blocks Narrow

A try block should cover one operation that can fail, not a whole function. Wrap the specific call you expect to raise; leave everything else outside.

When fifty lines share one handler, the handler can't say what failed, can't recover meaningfully, and catches bugs it was never written for.

- Put the try around the single failing operation: the `requests.get`, the `json.loads`, the file open — not the function body. Lines that can't raise the expected error don't belong inside
- One try block per distinct failure meaning: if the DB query and the HTTP call fail differently and matter differently, they get separate try blocks (or separate functions), not shared residence in one
- The narrower the block, the more the handler knows: `except requests.Timeout:` around just the call can say "payment-status check timed out for order {id}" and choose the right recovery — a function-wide handler can say only "error"
- Don't indent existing code into a new giant try as a way of "adding error handling" — that's adding error hiding; identify the fallible lines and wrap those
- Pure logic between fallible operations (arithmetic, dict access, formatting) stays outside try blocks so its bugs crash loudly instead of impersonating operational failures
- If a function needs five try blocks, that's often a sign it's five functions; refactoring beats one umbrella catch

**Red flags that you're about to violate this:**
- "I'll wrap the whole function to make sure nothing escapes..."
- "One try/except at the top level keeps it readable..."
- "Everything in here is risky, so the whole thing goes in the try..."
- "Indenting the body into a try is the quickest way to add handling..."
- "The handler can figure out what failed from the message..."
