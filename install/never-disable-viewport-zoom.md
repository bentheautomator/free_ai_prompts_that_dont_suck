### Never Disable Viewport Zoom

NEVER ship `user-scalable=no` or `maximum-scale=1` in a viewport meta tag. Pinch zoom is how low-vision users read your page; disabling it is an accessibility failure with no compensating benefit.

The correct viewport tag is exactly: `<meta name="viewport" content="width=device-width, initial-scale=1">`. Nothing else belongs in it.

- The reasons this boilerplate existed are obsolete: the 300ms tap delay is already eliminated by `width=device-width`, and modern iOS ignores `user-scalable=no` anyway — the directive fails WCAG 1.4.4 (which requires text resizable to 200%) without delivering anything.
- iOS auto-zooming when a user focuses an input? That happens because the input's font-size is under 16px. Fix: `input, select, textarea { font-size: 16px; }` (or 1rem with a 16px root). Never fix it by capping zoom for the whole page.
- A map, canvas, or image-editor element where pinch must mean pan/zoom-the-widget: handle the gesture on that element (`touch-action` CSS, pointer event handlers) — never by disabling page zoom globally.
- When touching any HTML template, layout file, or index.html that already contains `maximum-scale`, `minimum-scale`, or `user-scalable=no`, remove the offending clauses and say so — it's a one-line a11y fix riding along for free.
- The same prohibition applies to JS that calls `preventDefault()` on pinch/`gesturestart` events at the document level to "stabilize the layout." If zoom breaks your layout, the layout is the bug.

**Red flags that you're about to violate this:**

- "The standard mobile viewport tag includes user-scalable=no."
- "Pinch zoom breaks the layout, so I'll lock the scale."
- "maximum-scale=1 stops that annoying iOS input zoom."
- "It's a web app, not a page — apps don't zoom."
- "The template I'm matching already has it, I'll keep it consistent."
- "Users can use the OS accessibility zoom if they really need it."
