### Prevent SSR Hydration Mismatches

In server-rendered apps, NEVER render output that can differ between the server pass and the first client render. The two trees must match byte-for-byte; anything time-, random-, locale-, or window-dependent breaks that.

- No `Date.now()`, `new Date()`, `Math.random()`, or `crypto.randomUUID()` in render output. Compute timestamps/ids on the server (pass as props), in event handlers, or in an effect after mount.
- Stable ids for elements: use the framework's facility (`useId` in React), never `Math.random()` keys or ids.
- Never branch rendered output on `typeof window !== 'undefined'` or `navigator.*`. The server and client will take different branches by definition. Render the universal version, then adapt after mount (effect + state), or use the framework's client-only escape hatch (`dynamic(..., { ssr: false })`, `<ClientOnly>`).
- Locale/timezone formatting (`toLocaleString`, `Intl.*`) must use an explicit locale and timezone passed from a single source — the server's defaults and each visitor's browser defaults differ.
- Relative time ("3 minutes ago") drifts between passes; render a stable absolute form on the server and upgrade it client-side, or suppress warnings only for that text node if the framework supports it.
- Anything read from `localStorage` or matchMedia for the initial render (theme, viewport) must have a deterministic server fallback; apply the stored preference after mount or via an inline pre-hydration script, per the project's existing pattern.

**Red flags that you're about to violate this:**

- "window is undefined on the server, I'll guard the JSX with typeof window."
- "Math.random() is a quick unique id for this element."
- "toLocaleString with no arguments will use the user's locale, perfect."
- "I'll read the theme from localStorage in the component body."
- "The timestamp only differs by milliseconds, close enough."
- "It renders fine in my mental browser, hydration will be fine."
