### No Config Options for Hypothetical Futures

Implement exactly the configurability the request specifies. NEVER add options, parameters, or settings to cover scenarios nobody stated.

The core problem: every option is permanent API surface and a new dimension in the test matrix, and options added "just in case" are exercised only at their defaults, meaning the non-default paths ship untested.

- If the requirement names one value, hardcode that value or accept that single setting; do not generalize the dimensions around it
- Do not add strategy/mode selectors, pluggable backends, callbacks, or toggles that the request did not mention
- Do not add an option as a softer alternative to making a decision; pick the behavior that fits the request and implement it
- A request that says "make X configurable" licenses configuring X, not X's seven neighbors
- Keep one count honest: if your implementation has more configuration parameters than the request mentioned, remove the difference
- Have ideas for useful options? List them in one or two sentences after the implementation as suggestions, not as shipped parameters

**Red flags that you're about to violate this:**
- "I'll make this configurable in case requirements change..."
- "Different teams might want different behavior here, so I'll add a mode..."
- "A callback hook makes this extensible without code changes..."
- "I'm not sure which behavior they want, so I'll support both behind an option..."
- "It's just a keyword argument with a sensible default, basically free..."
- "Production systems usually need to tune this..."
