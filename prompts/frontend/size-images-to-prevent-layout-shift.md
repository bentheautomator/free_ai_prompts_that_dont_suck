---
title: Size Images to Prevent Layout Shift
slug: size-images-to-prevent-layout-shift
category: frontend
tags: [universal, frontend]
works_with: all
severity: medium
one_liner: "Stops dimensionless images and late content from yanking the page around"
---

# Size Images to Prevent Layout Shift

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping images, embeds, and async content with no reserved space, so the page stops jumping under the user's finger as things load.

**[Copy-paste ready version](../../install/size-images-to-prevent-layout-shift.md)** — just the instruction block, no explanation.

## The Problem

`<img src={product.image} alt={product.name} />` — no width, no height, no aspect ratio. The AI writes it, the image renders, the task is complete. What the AI never sees is the loading sequence: the browser lays out the page with the image at zero height, the text below it sits high, the image arrives 800ms later, and everything below jumps down by 300 pixels — ideally right as the user was about to tap "Cancel" and instead taps "Confirm." Multiply by every image in a feed and the page assembles itself like a slow earthquake while users try to read it.

The same hole opens around everything that arrives late: ad slots, embeds, web fonts swapping in at a different metric, and — the AI's specialty — content swapped in from a fetch with no placeholder sized like the result. A spinner that's 40px tall replaced by a 600px table is a layout shift the AI built deliberately. This is Cumulative Layout Shift, it's measured by Core Web Vitals, and past a threshold it costs search ranking along with user trust.

The AI omits dimensions because in its evaluation the image is always already loaded — there's no 3G in a mental render. Dimensions feel redundant ("CSS makes it responsive anyway"), and the old advice that fixed width/height fights responsive layouts still circulates, though `height: auto` resolved that conflict years ago.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It corrects the "attributes are legacy" belief.** Half the omissions come from outdated advice; explaining that width/height now feed aspect-ratio reservation (and don't fight responsive CSS with `height: auto`) removes the standing justification.
2. **It chases the dimensions upstream.** "I don't know the size" usually means "I didn't pass it through from the API/CMS where it exists" — the rule names that, converting an unknown into a plumbing task.
3. **It redefines loading states by size, not symbolism.** The spinner-to-table swap is a deliberate shift the AI doesn't count as one; "loading UI matches loaded dimensions" makes the skeleton's job spatial, not decorative.
4. **It frames late banners as a choice.** Push-down injections feel like neutral defaults; stating that anything appearing above content after paint is a chosen shift makes the overlay/reserve alternatives the default instead.

## Origin

A recipe site's listing page loaded text first, hero images second, with no reserved space. Users would tap a recipe and — as four thumbnails above finished loading — land on a different recipe entirely; the tap target moved 280px between intention and contact. Misclick-driven bounces were blamed on content quality for a quarter, until a Core Web Vitals report flagged the CLS score. Adding stored dimensions from the image pipeline took a day; the "wrong recipe" complaints stopped the same week.
