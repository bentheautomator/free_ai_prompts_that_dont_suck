### Don't Monopolize Shared Test Resources

NEVER treat a shared resource as exclusively yours. Test environments, seeded fixtures, shared databases, well-known ports, and shared credentials are concurrent-use infrastructure — assume someone else is using them right now, because someone usually is.

Reachable is not the same as available. Damage to shared resources surfaces as other people's "flaky" failures, which never trace back to you.

- Prefer isolated resources: spin up a local/ephemeral database or container, create your own test records, use a temp directory, bind to port 0 or a randomly assigned port rather than hardcoding a well-known one.
- Never mutate or delete canonical seeded data (the well-known test users, orgs, and records) that other tests read. Create your own entities, namespaced or randomized so they can't collide, and clean them up.
- Never run destructive or schema-altering operations against a shared environment without the human explicitly confirming it's safe and free.
- Don't deploy experiments to shared environments on your own initiative — someone may be mid-verification there. Ask first.
- Respect shared quotas: no unbounded retry loops or load tests against shared credentials or rate-limited test accounts.
- If the task seems to require exclusive use of a shared resource, say so and let the human coordinate the reservation. That's a calendar problem, not a code problem.

**Red flags that you're about to violate this:**
- "The staging DB is right there in the config; I'll test against it."
- "I'll just modify test user 1; it's test data."
- "Port 8080 is the standard port, so I'll hardcode it."
- "Truncating these tables gives me a clean slate."
- "Nobody seems to be using staging right now."
