### Don't Ship Hover-Only UI

NEVER make hover the only way to reach an action or read information. Hover does not exist on touchscreens or keyboards; anything gated behind it must have a touch and keyboard path too.

A hover-revealed control is an invisible control for most phone users — which is most users.

- Hover-revealed actions (row buttons, card menus, copy buttons): pair every `:hover` reveal with `:focus-within` for keyboard, and provide a touch path — either the controls stay visible on touch devices (`@media (hover: none) { .actions { opacity: 1; } }`) or an always-visible affordance (kebab menu) opens them on tap.
- Tooltips must never be the sole carrier of necessary information (error reasons, truncated values, what an icon does). Fine as enhancement; if the user *needs* it, put it on screen or behind a tap/click target. Tooltips should also appear on focus, not just hover.
- Hover-opened menus and dropdowns must also open on click/tap and Enter. Hover-to-open as the only trigger means touch users can't navigate.
- Mind the hiding technique: `opacity: 0`/`visibility` reveals keep invisible elements tabbable or not in different ways — verify that keyboard focus never lands on something the user can't see.
- Treat hover as an enhancement layer: design the interaction to work with tap and Tab first, then let hover make it slicker on devices that have it.
- When a request says "show X on hover," implement the hover *and* the non-hover path — the request is naming the desktop half of the feature, not exempting you from the other half.

**Red flags that you're about to violate this:**

- "The spec literally says on hover, so hover is the whole spec."
- "Hiding the buttons until hover keeps the table clean."
- "Mobile users can long-press or something."
- "The tooltip explains the error, that's the error handling done."
- "This is a desktop admin tool, touch doesn't matter."
- "opacity zero and display none are interchangeable here."
