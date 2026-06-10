### Preserve Keyboard Tab Order

NEVER use a positive `tabindex`, and never let visual order diverge from DOM order for interactive elements. Tab order comes from document structure; fix the structure, not the numbers.

Keyboard users experience the page as the tab sequence. Reordering or breaking it is a layout bug they can't see past.

- `tabindex` has exactly two sanctioned values: `0` (make a genuinely custom widget focusable in natural order) and `-1` (programmatic focus target, e.g. a heading to focus after route change). Positive values hijack the whole page's sequence — if focus order is wrong, reorder the elements in the markup.
- Never add `tabindex="-1"` to remove a working control from the tab order. If a control is operable by mouse, it must be reachable by Tab. (Exception: composite-widget patterns like roving tabindex inside a toolbar, where Arrow keys take over within the group.)
- When CSS reorders content (`order`, `row-reverse`, grid placement, absolute positioning), keyboard focus still follows the DOM. If the visual order matters, change the source order to match and style from there; don't paper over it with tabindex.
- Modals/drawers that overlay the page must contain Tab focus while open (and restore it on close); otherwise Tab wanders into the obscured page behind. Off-screen but rendered content (closed menus, inactive carousel slides) must not hold tab stops — hide it for real (`display: none`, `inert`, `visibility: hidden`), not just visually.
- After changing any layout or adding any interactive element, walk the change with the Tab key in your head: enumerate the focus sequence and check it matches reading order.

**Red flags that you're about to violate this:**

- "tabindex='1' on the search box puts it first, problem solved."
- "Focus shouldn't land on this button, tabindex='-1' it."
- "row-reverse gets the visual order right, ship it."
- "The menu is off-screen, so its links don't matter."
- "Tab order is an edge case for this internal tool."
- "I'll renumber all the tabindexes so the sequence works out."
