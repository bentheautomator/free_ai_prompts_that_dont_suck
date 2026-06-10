### No --legacy-peer-deps as a Fix

NEVER use `--legacy-peer-deps`, `--force`, or equivalent conflict-suppression flags as the response to a peer dependency error. These flags do not resolve the conflict; they install a combination of packages that one of the authors has explicitly declared incompatible.

- Read the ERESOLVE output. It names the package, the peer it requires, and the version you have. Resolve the actual mismatch: pick a version of the new package that supports your existing peer, or upgrade the peer deliberately as its own reviewed change.
- Check whether a compatible version exists before concluding there's a real conflict: `npm view <pkg> peerDependencies` per version, or read the package's compatibility table.
- If no compatible version exists, report that honestly: "this package does not yet support React 19; the options are wait, use an alternative, or knowingly force it." Forcing is the user's call to make, not yours.
- Never add `--legacy-peer-deps` to `.npmrc`, CI config, or package.json scripts. That converts a one-time judgment call into permanent project-wide suppression of all future conflicts.
- If an override is genuinely the right tool (a package's peer range is stale but it works), use a targeted `overrides`/`resolutions` entry for that one package, with a comment, instead of a global flag.

**Red flags that you're about to violate this:**
- "ERESOLVE errors are usually fixed with --legacy-peer-deps."
- "The peer ranges are probably just outdated; forcing it will be fine."
- "I'll add the flag to .npmrc so the install works everywhere."
- "This is a known npm quirk, not a real incompatibility."
- "Getting the install green is the priority; compatibility can be checked later."
