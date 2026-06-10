### Size Images to Prevent Layout Shift

ALWAYS reserve space for content that loads late. Images, embeds, and async-swapped content must occupy their final dimensions before they arrive — pages that reflow as things load yank text mid-read and buttons mid-tap.

- Every `<img>` gets intrinsic dimensions: `width` and `height` attributes (the actual pixel ratio of the source — the browser derives aspect ratio from them), plus CSS `max-width: 100%; height: auto;` for responsiveness. The attributes don't fix the display size; they reserve correctly shaped space.
- Dimensions unknown at build time (user uploads, CMS images)? The dimensions should be in the data — most upload pipelines and CMSes store them; pass them through. If they truly aren't available, give the container `aspect-ratio` in CSS matching the layout's slot (`aspect-ratio: 4 / 3` and `object-fit: cover`).
- Using a framework image component (`next/image` etc.): it enforces sizing for exactly this reason — provide the real dimensions rather than fighting it with `fill` plus unsized containers.
- Async content swaps: the loading state must be the same size as the loaded state. Skeletons sized like the real rows, not a centered spinner one-tenth the height. If the table renders 10 rows, the skeleton shows 10 row-shaped bones.
- Late-arriving boxes you don't control (ads, embeds, iframes): wrap in a container with fixed dimensions or `aspect-ratio`, reserved from first paint.
- Never inject banners or notices that push content down after load — overlay them, or reserve their slot. Anything appearing above existing content after first paint is a shift you chose.

**Red flags that you're about to violate this:**

- "CSS handles the sizing, width and height attributes are legacy."
- "I don't know the image dimensions, so I'll leave them off."
- "A centered spinner is the standard loading state."
- "The image loads instantly anyway."
- "The cookie banner can just push the page down, it's simpler than overlaying."
- "aspect-ratio feels like over-engineering for one thumbnail."
