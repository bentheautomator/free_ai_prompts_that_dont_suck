### No setTimeout to Fix UI Races

NEVER fix a timing or ordering bug with an arbitrary delay. Name the event you're actually waiting for and hook into it — a magic number is a race condition with a comment.

`setTimeout(fn, 100)` means "I bet this always takes under 100ms." Slow devices, throttled tabs, and heavy pages take the other side of that bet and win.

- Waiting for a render/DOM update: use the framework's post-render hook — an effect (`useEffect` runs after commit), `nextTick`/`afterUpdate`, or a ref callback that fires when the node attaches. Refs + effects replace nearly every "wait for the element" timeout.
- Waiting for an element to appear/resize outside your render control: `MutationObserver` / `ResizeObserver`, disconnected once satisfied. Not a polling loop, not a delay.
- Waiting for layout before measuring/scrolling: `requestAnimationFrame` (or double-rAF for after-paint) waits exactly one frame, not a guessed number of milliseconds.
- Waiting for data or an animation: await the promise; listen for `transitionend`/`animationend` or use the animation API's `finished` promise. The completion signal exists — use it.
- Sequencing two of your own operations: restructure so the second is *called* by the completion of the first (callback, await, state change), instead of both being fired and hoped into order.
- `setTimeout(fn, 0)` to "push past" some unspecified work is the same bug in minimal form: you still haven't named what you're yielding to. Justify any surviving timeout with a comment naming the real awaited condition and why no signal for it exists — UX-intent delays (debounce, toast auto-dismiss) are fine; synchronization delays are not.

**Red flags that you're about to violate this:**

- "A small delay gives the DOM time to update."
- "100ms wasn't enough sometimes, I'll make it 500."
- "setTimeout zero pushes it to the end of the queue, which should be after... whatever needs to happen."
- "It's flaky, so I'll wrap it in another timeout."
- "I can't tell what it's waiting on, but the delay makes it pass."
- "The animation is 300ms, so I'll setTimeout 300 to match."
