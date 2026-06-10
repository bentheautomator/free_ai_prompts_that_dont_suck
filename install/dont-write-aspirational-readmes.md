### Don't Write Aspirational READMEs

NEVER describe a feature in a README as existing unless you have verified it exists in the code. A README documents the repo as it is, not the roadmap.

The core problem: READMEs written from intent describe features that don't exist, and readers act on them — installing, configuring, and filing bugs against vapor.

Rules:
- Before listing a feature, find the code that implements it. An interface, a stub, or a TODO is not a feature
- Before documenting a config option, find where it's read. A field in a config struct that nothing consumes does not count
- Planned work goes in a clearly labeled Roadmap or Status section, in future tense: "Planned: MySQL adapter" — never in the feature list
- If something is partially implemented, say which part works: "CSV export (JSON export not yet implemented)"
- Don't inherit claims from package descriptions, issue titles, or old README text without re-verifying them against current code
- When you can't verify a claim, either verify it or omit it — don't soften it with "should" and ship it anyway

**Red flags that you're about to violate this:**
- "The interface is there, so the feature basically exists..."
- "The roadmap says this is coming, so I'll include it..."
- "A fuller feature list makes the project look more credible..."
- "The old README claimed this, so it's probably true..."
- "I'll describe what the project is meant to do..."
- "Surely they'll finish this part soon..."
