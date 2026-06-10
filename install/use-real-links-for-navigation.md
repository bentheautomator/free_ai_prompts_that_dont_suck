### Use Real Links for Navigation

If activating it changes the URL, it's a link: an `<a href>` (or the router's `<Link to>`), NEVER a click handler on a div, span, or button.

Real links carry a toolkit users rely on — new tab, copy address, middle-click, status-bar preview, screen reader link lists, crawlability. An onClick that calls `navigate()` discards all of it for zero benefit.

- In-app navigation in an SPA: the router's link component (`<Link to=...>`, `<router-link>`, framework equivalent). It renders a true `<a href>` and intercepts plain left-clicks for client-side routing while letting modified clicks (Cmd/Ctrl/middle/Shift) reach the browser. That split is the whole point — reimplementing it in onClick gets it wrong.
- Never `href="#"` or `href="javascript:void(0)"` as a mount point for handlers. If there's a destination, put it in `href`; if there's no destination, the element is a button — use `<button>`.
- The decision rule: changes the URL → link; performs an action staying on the page → button. "Log out" is a button. "View order" is a link. A card that opens a detail page is a link even though it's a card — wrap or embed a real `<Link>` and extend its hit area with CSS if needed.
- Programmatic `navigate()`/`router.push()` is for navigation that *isn't* user-clicks-a-thing: post-submit redirects, auth bounces, wizard advancement. Using it as a click handler's body on a clickable element is the anti-pattern.
- Don't suppress link affordances: no `onClick={e => e.preventDefault()}` wrappers around real links to force SPA behavior the Link component already provides, and never intercept modified clicks.
- Buttons styled as links and links styled as buttons are fine — CSS is free; semantics aren't.

**Red flags that you're about to violate this:**

- "onClick with navigate() does the same thing as a Link."
- "The whole card is clickable, so the div gets the handler."
- "href='#' stops it from actually navigating, then my JS takes over."
- "Nobody middle-clicks in a web app."
- "I'll preventDefault and handle routing manually for more control."
- "It navigates when I click it — navigation works."
