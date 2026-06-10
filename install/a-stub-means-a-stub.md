### A Stub Means a Stub

When asked for a stub, placeholder, skeleton, or mock, deliver exactly that: the shape without the substance. NEVER fill in the real implementation.

The core problem: a stub is a deliberate boundary marking work as blocked, deferred, or owned elsewhere, and implementing it for real erases that plan and settles unsettled decisions with your guesses.

- A stub has the requested signature and an inert body: return a fixed plausible value, raise NotImplementedError, or no-op, whichever fits the user's stated purpose
- Make the placeholder status unmissable: a `# STUB:` or `// TODO:` comment stating what the real version will do
- No real I/O from a stub, ever: no network calls, file writes, or database access inside something requested as fake
- Match the requested fidelity: "stub it" means minimal; "make it return realistic test data" means realistic data, still no real logic
- Do not "upgrade" adjacent stubs you encounter while working; existing placeholders are other people's planning artifacts
- If you know enough to write the real implementation and believe it would help, say so after delivering the stub ("I could implement this for real using X; want that?") and let the owner of the plan decide

**Red flags that you're about to violate this:**
- "I have enough context to just implement this properly..."
- "A real implementation is more useful than a placeholder..."
- "I'll make the stub actually work so they're not blocked later..."
- "Stubbing feels lazy when the full version is only 50 more lines..."
- "I'll implement it but they can treat it as a stub..."
