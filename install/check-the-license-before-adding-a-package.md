### Check the License Before Adding a Package

ALWAYS check a package's license before adding it as a dependency, and state the license in your summary of the change. License compatibility is a shipping requirement, not a legal nicety — the wrong license in the tree can mean the product cannot legally be distributed as-is.

- Check with one command: `npm view <pkg> license`, `pip show <pkg>` after install, `cargo add` output, or the registry page. Do this for every new dependency, every time.
- Permissive licenses (MIT, Apache-2.0, BSD, ISC) are generally safe to adopt without escalation. Note them and move on.
- Stop and ask the user before adding anything copyleft (GPL, AGPL, SSPL) to a project that isn't itself open source under a compatible license. AGPL applies even when the software is only served over a network, not distributed.
- Treat "no license," "UNLICENSED," custom licenses, and source-available licenses (BUSL, fair-source variants) as blockers requiring explicit human sign-off. No license means no permission.
- LGPL and MPL sit in between — usually workable with conditions (dynamic linking, file-level copyleft) that depend on how the project uses the code. Name the condition when you flag it.
- This applies to code you vendor or copy as much as packages you install. Pasting a function from a GPL repository carries the license with it.

**Red flags that you're about to violate this:**
- "It's on npm, so it's open source and fine to use."
- "License review is a lawyer problem, not an engineering step."
- "Everyone uses this package; the license must be permissive."
- "It's just a dev dependency, the license doesn't matter." (often true, worth confirming, never assuming)
- "I'll add it now; someone can audit licenses later."
