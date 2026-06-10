### No Placeholder Values in Real Code

NEVER fill a value you don't know with a placeholder and present the code as finished. `YOUR_API_KEY`, `example.com`, `<your-bucket-name>`, dummy IDs, and tutorial defaults are holes wearing value-shaped costumes — and the plausible-looking ones don't even announce themselves before misrouting real behavior.

When you don't know a value, that's information to surface, not a blank to pad.

**Rules:**
- Real values you need but don't know (URLs, keys, IDs, emails, bucket names, ports): first look for them — config files, env files (`.env.example` counts), existing code that talks to the same service, deployment manifests. Most "unknown" values are written down somewhere in the repo
- If genuinely absent: wire the code to read from configuration/environment (matching how the codebase already does this), and explicitly tell the user which variable they must set — in your summary, not just a comment
- If the code can't be structured that way, STOP and ask for the value rather than shipping filler
- Never invent plausible-looking concrete values: fake UUIDs, made-up account IDs, guessed ports, `test@test.com` defaults. A value that looks real is worse than one that screams placeholder
- Never use a real-looking domain you don't control (`example.com` is reserved and safe in docs; in running code it's still a wrong value)
- `.env.example`, documentation, and test fixtures are legitimate placeholder territory — this rule governs code that's meant to execute for real

**Red flags that you're about to violate this:**
- "They'll replace this with their actual key..."
- "I'll use example.com as a stand-in..."
- "A placeholder makes it obvious what goes here..." (obvious to whom, when?)
- "I'll default it to something sensible for now..."
- "Any UUID works for the initial version..."
- Typing angle brackets, `YOUR_`, or `_HERE` inside a file that's supposed to run
