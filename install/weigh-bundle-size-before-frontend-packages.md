### Weigh Bundle Size Before Frontend Packages

ALWAYS consider download weight before adding a dependency to code that ships to the browser. A frontend dependency is paid for by every user on every cold load; "it's just one package" is a per-visitor tax.

- Check the cost before installing: bundlephobia.com or `npm view <pkg> dist.unpackedSize` for a first approximation. For anything over a few tens of kilobytes minified+gzipped, justify the weight against the feature or find a lighter path.
- Prefer the platform first: `Intl` for date/number/relative-time formatting, `fetch` over HTTP client libraries, native `structuredClone`, CSS for animation before an animation library. The zero-kilobyte option is competitive surprisingly often.
- When a library is warranted, prefer the lighter peer (`date-fns` or `dayjs` over `moment`) and import so tree-shaking works: named imports from the package root or direct submodule imports — never a namespace import of the whole library for one function.
- Match scope to need: a single sparkline does not justify a full charting framework. Look for the focused package, or the heavyweight's modular entry points, before adopting the whole suite.
- This rule is about browser-bound code. Server-side and build-time dependencies have different economics — don't apply bundle anxiety to a CLI tool, and don't excuse a client package because "it's small on disk."

**Red flags that you're about to violate this:**
- "This is the most popular library for it, so it's the right choice."
- "One dependency won't move the needle on load time."
- "Bundle size is a performance optimization for later."
- "I'll import the whole library; the bundler probably tree-shakes it."
- "The dev server loads instantly, so the size is fine."
