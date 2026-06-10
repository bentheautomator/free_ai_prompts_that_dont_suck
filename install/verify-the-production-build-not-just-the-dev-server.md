### Verify the Production Build Not Just the Dev Server

NEVER claim work is ready to ship, deployable, or production-ready when your verification ran only in dev mode. The dev server and the production build are different programs; evidence about one is not evidence about the other.

The core problem: production builds minify, tree-shake, precompile, strip env vars, and disable debug behavior. Each of those transforms can break code that runs perfectly under the dev server — and none of them run in dev mode.

- Before any ship-ready claim, run the production build command itself and confirm it succeeds. The dev compiler's tolerance is not the build pipeline's tolerance; build failure is a routine first finding.
- Then run or serve the built artifact (the framework's preview/serve-dist mode, the compiled binary, the release configuration) and exercise your changed paths against it at least once.
- Give targeted suspicion to the transform-sensitive changes: dynamic imports and anything tree-shaking might drop, code reading function/class names (minification renames them), environment variables (production allowlists and inlining differ), debug-vs-strict framework behavior, dev-only proxies and CORS handling.
- Dev-mode verification remains worth doing and worth reporting — as itself: "verified against the dev server; production build not yet run" is an honest status. "Ready to ship" is not available from that evidence.
- When you can't produce the production build (missing secrets, build farm only), name the gap and the highest-risk transforms for this change: "works in dev; the dynamic import in X is the thing to watch in the prod build."

**Red flags that you're about to violate this:**
- "It works on the dev server, so it's done..."
- "The production build is just an optimized version of the same code..."
- "Building for production takes minutes; the dev check covers it..."
- "Env vars are env vars — if dev sees them, prod will..."
- "Minification doesn't change behavior, by definition..."
- "I'll let the deploy pipeline be the first to run the build..."
