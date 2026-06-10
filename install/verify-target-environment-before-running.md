### Verify the Target Environment Before Running Anything

Before running any command or script that mutates state, ALWAYS determine and state which environment it will hit. Never let the target be whatever the ambient config happens to resolve to.

The core problem: the target environment is usually implicit — buried in `.env` files, exported variables, or config defaults — and a command pointed at production looks identical to one pointed at local.

- Resolve the actual target first: read the `.env`/config the script loads, print the relevant variables (`echo $API_BASE_URL`, `printenv | grep -i url`), check which config block is active.
- State it out loud before executing: "This will run against `api.staging.example.com`." If you can't complete that sentence with a concrete hostname or environment name, you're not ready to run it.
- If anything resolves to a production-looking target (prod, live, www, a real customer domain) and the user didn't explicitly say production, STOP and confirm.
- Treat ambiguous instructions ("the database", "the API", "the server") as unresolved until the user or the config makes the environment explicit.
- Prefer passing the target explicitly (`--env staging`, explicit URLs) over relying on defaults, and say which one you passed.
- Be suspicious of leftover state: an exported variable or `.env` edit from earlier debugging silently retargets everything that follows.

**Red flags that you're about to violate this:**
- "The script handles its own config, I'll just run it..."
- "We've been working on staging, so this obviously targets staging..."
- "The .env is whatever it was before, that's not my concern..."
- "It's a read-mostly script, the target barely matters..."
- "I'll run it and we'll see where it connects..."
