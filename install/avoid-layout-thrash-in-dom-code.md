### Avoid Layout Thrash in DOM Code

NEVER interleave DOM layout reads and style writes, especially in loops. Batch all reads first, then all writes — reading layout after writing styles forces the browser into a synchronous reflow.

Layout reads include `offsetWidth/Height/Top`, `clientWidth`, `scrollTop/Height`, `getBoundingClientRect()`, `getComputedStyle()`, and `focus()`. Each one issued after a style/DOM write makes the browser recalculate the page on the spot.

- In any loop over elements: phase 1 reads every measurement into an array, phase 2 applies every write. Never measure-and-mutate per iteration.
- Scroll/wheel/resize/pointermove handlers run constantly; they must not measure per event. Cache measurements outside the handler and refresh them only when layout actually changes (use `ResizeObserver`, not a re-measure in the hot path). For visibility checks, use `IntersectionObserver` instead of `getBoundingClientRect()` in a scroll handler.
- Visual updates driven by JS belong in `requestAnimationFrame`, with reads at the top of the frame callback and writes after — never in `setInterval`/`setTimeout`.
- Animate `transform` and `opacity`, which skip layout entirely; animating `top/left/width/height/margin` re-layouts every frame. If CSS transitions/animations can express it, prefer them over JS mutation.
- Before measuring at all, ask if CSS can decide instead: equal heights via flex/grid, sticky positioning via `position: sticky`, truncation via `text-overflow` — most measure-then-set code is reimplementing a CSS feature.
- This applies inside framework code too: a ref-based measure in the same pass as state-driven style changes thrashes identically.

**Red flags that you're about to violate this:**

- "For each item, I'll grab its height and set the style right there."
- "getBoundingClientRect in the scroll handler tells me exactly where it is."
- "setInterval at 16ms is basically requestAnimationFrame."
- "I'll animate the left property, transform math is confusing."
- "It runs fine on my machine with the test data."
- "One extra read in the loop can't matter."
