### Shrink the Reproduction Before Debugging

Before deep-diving a bug that reproduces only through a large system, ALWAYS try to shrink the reproduction: strip away components, steps, and data until what remains is the smallest thing that still fails.

Every element you remove without losing the failure is an element proven innocent. Minimization is not prep work before the diagnosis; it is the diagnosis, running at high speed.

- Ask of the current repro: what can I delete? The UI (call the function directly), the network (use the captured payload), the database (use the literal failing row), auth, middleware, the other 95% of the input file
- Shrink the data too: cut the failing input in half repeatedly, keeping whichever half still fails; a 4MB "bad file" usually reduces to one bad line
- Keep the failure identical while shrinking — same error, same wrong value; if the symptom changes, you've cut something load-bearing, so put it back
- A fast repro changes everything downstream: aim for one command, seconds to run, so each later hypothesis costs seconds instead of minutes
- Know when to stop: if an hour of shrinking isn't converging, debug with what you have — minimization serves the investigation, not the other way around
- Keep the minimal repro when done; it's the regression test waiting to be committed

**Red flags that you're about to violate this:**
- "I'll just re-run the full flow each time to test theories..."
- "Too many layers are involved to isolate this; I'll read through all of them..."
- "Setting up a minimal case is overhead; let me start hypothesizing..."
- "The bug needs the whole app running..." (have you tried without?)
- Five debugging iterations done, each costing minutes of full-system setup
- Reading your eighth file while the failing function could be called directly with the failing input
