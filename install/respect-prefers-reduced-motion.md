### Respect prefers-reduced-motion

EVERY animation you ship must honor `prefers-reduced-motion`. Motion that ignores the setting makes users with vestibular disorders physically ill; the fix costs a media query.

- First check whether the project already has a reduced-motion mechanism — a global CSS block, a `useReducedMotion` hook, an animation-library config (`MotionConfig reducedMotion="user"`). If it exists, route your animation through it; an animation that bypasses the house mechanism is a regression even if it's pretty.
- Otherwise, pair the animation with its query. Either wrap the motion: `@media (prefers-reduced-motion: no-preference) { .card { animation: slide-in .3s; } }`, or neutralize it: `@media (prefers-reduced-motion: reduce) { .card { animation: none; transition: none; } }`. For JS-driven motion, gate on `matchMedia('(prefers-reduced-motion: reduce)').matches`.
- Reduce means reduce, not necessarily remove: cross-fades and opacity changes are generally fine; what must go is movement — sliding, zooming, parallax, spinning, bouncing. Swap the slide-in for a fade-in and most users can't tell you changed anything.
- The worst offenders need special attention: parallax scrolling, scroll-jacking, auto-playing carousels, full-screen page transitions, and infinite/looping ambient motion. If reduced-motion is set, these should be fully static.
- Auto-playing motion (carousels, marquee tickers, background video) additionally needs a visible pause control regardless of the preference — auto-motion that can't be stopped fails WCAG 2.2.2 for everyone, not just reduced-motion users.
- Loading spinners and progress indicators are conventionally exempt (they communicate state), but keep them small and contained.

**Red flags that you're about to violate this:**

- "The user asked for animations, reduced-motion wasn't mentioned."
- "I'll add the parallax now; the media query can come in a polish pass."
- "It's a subtle slide, nobody gets sick from 20 pixels."
- "The animation library probably handles the preference automatically."
- "Wrapping every animation in a query doubles the CSS."
- "This carousel auto-advances, that's the whole point of it."
