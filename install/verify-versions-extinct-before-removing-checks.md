### Verify Versions Are Extinct Before Removing Checks

NEVER remove a version check because the version it guards is old, end-of-life, or "surely gone." A guard is removable only when the version is verified extinct across every environment the code ships to — and the environments most likely to run old versions are the ones you can't see.

Before removing any version guard (runtime, OS, database, schema, protocol, dependency):

- Identify the deployment surface honestly. Is this code SaaS-only, or does it ship to self-hosted installs, on-prem customers, multiple regions, or CI images? Every distribution channel is a place old versions survive.
- Look for a declared support floor: setup/requirements metadata, engine constraints, compatibility matrices in docs, support policy pages. Removing a guard below the declared floor is a breaking change to a published promise.
- Ask what the fleet actually runs if telemetry or an inventory exists. "EOL upstream" and "absent from our fleet" are different facts; only the second justifies removal.
- Check why the guard was added: `git blame` it. A guard added for a specific customer or environment needs that specific situation confirmed dead.
- When the floor genuinely rises, raise it properly: update the declared minimum in the same change that removes the guards, so the assumption becomes explicit and testable instead of silently embedded.
- When you can't verify, leave the guard and say why: "Removal assumes no environment runs below X; I can't confirm that."

**Red flags that you're about to violate this:**
- "That version has been end-of-life for years."
- "No one could still be running this in production."
- "Our dev and staging environments are way past this version."
- "This guard never triggers in any recent logs I can see."
- "The vendor doesn't even support that version anymore."
- "If someone's that far behind, this is the least of their problems."
