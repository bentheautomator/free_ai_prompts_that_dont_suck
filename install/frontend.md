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

### Never Remove Focus Outlines

NEVER write `outline: none`, `outline: 0`, or `box-shadow: none` on a `:focus` state without providing a replacement focus indicator in the same rule. No exceptions for "the designer doesn't like it."

The default outline is the only thing telling keyboard users where they are. Removing it without a substitute makes the page unnavigable for them, and it's invisible in mouse-based testing.

- If the default outline clashes with the design, restyle it; don't delete it. Replace with a visible custom indicator: `outline: 2px solid <color>; outline-offset: 2px;` or an equivalent high-contrast `box-shadow` ring.
- Use `:focus-visible` instead of `:focus` to hide the ring for mouse clicks while keeping it for keyboard focus. That solves the "ugly ring on click" complaint without harming anyone: `button:focus-visible { outline: 2px solid currentColor; }`
- Never put focus-outline removal in a global reset (`*:focus`, `a:focus`, `button:focus`). One global line breaks the entire site.
- A custom indicator must be visible against the actual background: minimum 2px, contrast it against the surface it sits on, and check it on both light and dark variants if the app has them.
- When touching any existing stylesheet, treat an existing `outline: none` without a replacement as a bug worth flagging, not a convention to copy.

**Red flags that you're about to violate this:**

- "The user said the ring looks ugly, so I'll remove the outline."
- "I'll add `outline: none` to the reset for a cleaner baseline."
- "This button has a hover style, so focus styling is redundant."
- "Nobody tabs through this part of the UI anyway."
- "The existing CSS already removes outlines elsewhere, so I'll match it."
- "I'll remove it now and we can add a custom indicator later."

### Derive UI State, Don't Store It

NEVER store a value in state that can be computed from existing state or props during render. Compute it where it's used; state is only for things that cannot be derived.

Every stored copy of derivable data is a synchronization bug waiting for the one code path that forgets to update it.

- Filtered/sorted/mapped lists: `const visible = items.filter(...)` in render. Not a second state variable synced by an effect.
- Counts, totals, flags: `const isEmpty = items.length === 0`, `const hasChanges = draft !== original`. Expressions, not state.
- Selection: store the selected `id`, derive the selected object (`items.find(i => i.id === selectedId)`). Storing the object means it goes stale when the item updates.
- If the computation is genuinely expensive, memoize it (`useMemo`, `computed`) — memoization is derivation with a cache, and it cannot drift. Don't reach for it preemptively; most filters over UI-sized lists are free.
- The pattern `useState` + `useEffect` that only calls the setter from values already in scope is the tell. If an effect's only job is keeping state B in sync with state A, delete state B.
- Legitimate state: user input, fetched data, and anything that can't be recomputed from what you already have. If you can write the value as a pure function of other state, it isn't state.

**Red flags that you're about to violate this:**

- "I'll keep filteredItems in state and update it when the filter changes."
- "I need this value in two places, so it should be state."
- "An effect can keep the count in sync with the list."
- "Storing the selected object saves a lookup."
- "Recomputing on every render feels wasteful."
- "I'll add state for this now and make sure to update it everywhere."

### Don't Break the Browser Back Button

ALWAYS decide, for any UI state change, what the back button should do afterward — and make history match that answer. Users treat Back as undo for navigation; UI that feels like navigation must behave like it.

- If a change feels like "going somewhere" — wizard steps, detail views, opened full-screen panels, tab selection that users would deep-link — it belongs in the URL (route or query param) so Back returns to the previous view, not the previous page.
- If a change is rapid-fire refinement — keystrokes in a search box, toggling filters — update the URL with `replaceState` (or the router's `replace: true`) so the state is shareable and reload-safe but doesn't stack a history entry per interaction. One coarse-grained push when the user "commits" (submits, navigates) is fine; one per keystroke is vandalism.
- Modals and drawers: pick one behavior and implement it fully. If Back should close the modal, push an entry on open and close on `popstate`; if not, don't touch history. Never push on open without handling the pop — that strands a junk entry.
- Never chain redirects such that Back lands on a page that immediately re-redirects forward. Use `replace` for the intermediate hop.
- Restore scroll position and state when the user comes Back; if your data refetch resets the list and loses their place, the navigation isn't done.
- Test the flow backward: after every step you build, ask "user presses Back here — where do they land, and did they lose work?"

**Red flags that you're about to violate this:**

- "The wizard step can just live in component state."
- "I'll push a history entry on every filter change so it's all in the URL."
- "Nobody uses the back button inside a flow like this."
- "pushState and replaceState are basically the same thing."
- "The modal closing on Back is a nice-to-have, skip for now."
- "Back works in my flow — I clicked through it forward and it was fine."

### Don't Default to useEffect

NEVER reach for `useEffect` until you've ruled out render and event handlers. Effects are for synchronizing with external systems (network, DOM APIs, subscriptions, timers) — not for reacting to your own state.

Each unnecessary effect adds a render cycle, a frame of staleness, and a dependency array to get wrong.

- Transforming data for display (filter, sort, derive, format): compute it in render. Expensive? `useMemo`. Never effect-plus-setState — that's a cache that can drift and double-renders by design.
- Responding to a user action (submit, click, select): put the logic in the event handler. Don't set a flag in the handler and have an effect watch the flag — that severs cause from effect and fires on every path that touches the flag, not just the user's action.
- Resetting state when a prop changes (e.g., new `userId` clears the form): pass `key={userId}` to remount, or derive what you can. An effect that mirrors props into state is two sources of truth.
- Notifying a parent of a change: call the callback in the event handler that caused the change, not in an effect watching the changed value.
- Legitimate effects: fetching on mount (when the project isn't using a data library), subscribing to events/stores/sockets, syncing to localStorage or document.title, driving non-React widgets. The test: does this synchronize React state with something outside React? If both ends are React state, it's not an effect.
- Before writing any effect, state which external system it synchronizes with. No external system, no effect.

**Red flags that you're about to violate this:**

- "When X changes, I need to update Y — that's a useEffect."
- "I'll set a flag on submit and let an effect do the actual work."
- "An effect keeps this derived list up to date."
- "I'll sync the prop into local state when it changes."
- "Chaining effects keeps each step small and clean."
- "The lint rule wants this dep, I'll add it — what loop?"

### Don't Mirror Props Into State

NEVER copy a prop into state just to render it. `useState(props.x)` snapshots the prop at first mount and ignores all later updates — it's a staleness bug with the syntax of normal code.

- Displaying a prop (possibly transformed): read it directly in render. `props.user.name`, or `const fullName = ...` derived in render. No state, no effect, always current.
- The component edits the value? Choose the relationship deliberately:
  Controlled — parent owns the value; the component renders `props.value` and calls `props.onChange`. No internal copy exists to go stale.
  Uncontrolled with initial default — the snapshot is intentional (a draft seeded from the prop). Name the prop accordingly (`initialValue`, `defaultValue`) so the contract is explicit, and have the parent pass `key={record.id}` so a new record remounts the editor with a fresh draft.
- NEVER patch staleness with `useEffect(() => setX(props.x), [props.x])`. That re-implements direct prop reading with extra renders, sync gaps, and clobbered in-progress edits. If you're writing that effect, the component's ownership design is wrong — fix the design.
- Deciding factor: who should win when the prop changes mid-edit? Parent wins → controlled. User's draft wins until they reset → uncontrolled + `key`. "Both somehow" is not an option; the sync-effect is an attempt at "both" and delivers neither.
- When editing existing components, treat `useState(props.anything)` without an `initial`/`default` name as a latent bug worth flagging.

**Red flags that you're about to violate this:**

- "I'll stash the prop in state so the component has its own copy."
- "useState(props.value) is a convenient default."
- "It's not updating? A useEffect can sync the prop into state."
- "Local state makes the component more self-contained."
- "I'll keep state and prop both, and reconcile when they differ."
- "It rendered the right value when I checked" (you checked the first render).

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

### Give Every Form Input a Label

EVERY form control gets a programmatically associated label. A placeholder is not a label — it disappears on input and is unreliable for assistive tech.

- Default pattern: `<label htmlFor="email">Email address</label><input id="email" />`, or wrap the input inside the label. The `id` must be unique on the page (in reusable components, generate it — `useId` — don't hardcode it).
- The design shows no visible label? Use a visually-hidden label (the project's `.sr-only`/`.visually-hidden` class) or `aria-label="Email address"` — not nothing. Minimal design is a styling decision, not a semantics decision.
- Placeholders are for format hints (`placeholder="name@example.com"`), supplementary to a label, never instead of one.
- Checkboxes and radios especially: the clickable text next to them must be their real `<label>`, both for screen readers and because it makes the text a click target — a bare `<span>` next to a checkbox is two bugs.
- Selects, textareas, and custom widgets (comboboxes, date pickers) follow the same rule; for custom widgets, ensure the visible label is wired via `aria-labelledby` to the focusable element.
- Verify the association the cheap way: clicking the label text must focus (or toggle) the control. If it doesn't, the wiring is broken regardless of how it looks.
- Group related controls: radio groups and checkbox sets get a `<fieldset>` with a `<legend>` naming the question, or the individual options read as context-free fragments.

**Red flags that you're about to violate this:**

- "The placeholder says what the field is, that's the label."
- "The mock has no labels, so the form has no labels."
- "I'll add the label element; wiring the for attribute is just ceremony."
- "It's one search box, everyone knows what it's for."
- "I'll reuse id='input' like the other instances do."
- "The checkbox text is right next to it, the association is obvious."

### Keep Heading Levels Semantic

Choose heading levels by document outline, NEVER by font size. The level says where content sits in the hierarchy; CSS says what it looks like. These are independent decisions — make them independently.

Screen reader users navigate by jumping between headings. A skipped or size-chosen level hands them a table of contents that lies.

- One `<h1>` per page: the page's subject. Top-level sections get `<h2>`, their subsections `<h3>`, and so on. Never skip down levels (h2 to h4) — if the design wants the h3 to look small, style the h3 small.
- Need a big bold non-heading (a stat, a price, a tagline)? That's a styled `<p>`, `<span>`, or `<div>` — not a heading tag borrowed for its size. Conversely, anything that titles a section of content is a heading tag, even if the design renders it tiny and gray.
- In reusable components, don't hardcode the level — a card titled with `<h2>` is wrong in half its placements. Accept the level as a prop (`as`/`headingLevel`) or document the component's expected nesting depth.
- Don't restyle by re-tagging: when asked to make a heading smaller/larger, change its CSS class and leave the tag alone unless the document structure itself changed.
- Sections introduced by visual styling only (a divider and bold text as a div) still need a real heading for non-visual users — restyle a real `<hN>` to match.
- Quick self-check before finishing a page: read just the heading tags top to bottom. They should form a sane nested outline of the content with no jumps.

**Red flags that you're about to violate this:**

- "The mock's section title is small, so h4 fits the size."
- "This title needs custom styling, a div is easier than fighting h2 defaults."
- "Another h1 here gives it the right visual weight."
- "I'll bump it from h2 to h3 to make it smaller, like the user asked."
- "The card component uses h2; it'll be fine wherever it lands."
- "Heading levels are an SEO nicety, not a functional thing."

### Keep Native Form Submit Working

ALWAYS build forms as a real `<form>` with the logic in `onSubmit`. Enter-to-submit, native validation, autofill, and password managers all hang off the form element — a div of inputs with an onClick button has none of them.

- Structure: `<form onSubmit={handleSubmit}>` with a `<button type="submit">`. The handler calls `event.preventDefault()` (when submitting via JS) and lives on the form, not the button — that's what makes Enter in any field, the mobile keyboard's go key, and the button all converge on one code path.
- EVERY other button inside a form gets explicit `type="button"`. The default type is `submit`, so an untyped "show password" or "remove item" button silently submits the form. This is the single most common form bug; type every button.
- Use real input types (`email`, `password`, `tel`, `number`, `url`) and `autocomplete` attributes (`autocomplete="email"`, `"current-password"`, `"new-password"`). They drive mobile keyboards, autofill, and password managers — stripping them to generic `text` breaks all three.
- Don't suppress native validation reflexively. `required`, `minLength`, and pattern checks are free; add `noValidate` only when the project's validation library replaces them with something at least as visible.
- Never block paste, autofill, or autocomplete on credential or code fields ("paste disabled for security" is security theater that mostly punishes password-manager users).
- Test the paths you didn't click: would Enter from the last field submit? Would clicking each auxiliary button leave the form unsubmitted?

**Red flags that you're about to violate this:**

- "The button's onClick submits it, the form tag is redundant."
- "I'll wire up Enter handling with a keydown listener later if needed."
- "It's just a toggle button inside the form, no type needed."
- "preventDefault on the button click covers the reload."
- "Generic text inputs are simpler than fiddling with types."
- "Clicking submit works, the form is done."

### Keep UI State Local, Not Global

NEVER put state in the global store unless more than one distant part of the app reads it. Default to component-local state; hoist only when a second consumer actually exists.

The global store is for shared state. A dropdown's open flag, an input's draft value, a hover or focus flag — these have one consumer, and putting them in the store gives them the wrong lifetime and re-render scope.

- Open/closed, expanded/collapsed, hovered, focused, active-tab-within-a-widget: `useState` (or the framework's local equivalent) in the component that renders it.
- Form drafts: local to the form (or the form library's own state) until submitted. Globalizing drafts means stale text resurfaces when the user returns to the form for a different record.
- Hoist exactly as far as needed: two sibling components sharing state means lift to their parent, not to the store.
- "Some other component might need this someday" is not a second consumer. Hoist when the need exists, not speculatively — moving state up later is a mechanical refactor.
- Legitimate store residents: the authenticated user, theme, cross-page selections, anything a deep-linked or distant component reads. If you can name the two distant consumers, it can go global.
- Don't mirror local state into the store "for debugging visibility" — that creates two sources of truth that drift.

**Red flags that you're about to violate this:**

- "This project uses Redux, so new state goes in Redux."
- "I'll put the modal flag in the store so anything can open it later."
- "Global state is easier to wire than passing one prop."
- "The store already has a ui slice, this fits right in."
- "Keeping all state in one place is cleaner architecture."
- "I'll sync the local value into the store too, just in case."

### Make Modals Actually Modal

A modal is a behavior contract, not a styled overlay. NEVER ship a dialog that doesn't trap focus, close on Escape, and render the background inert.

- First choice: the project's existing modal/dialog component or library primitive — never a new bespoke overlay div beside an established one. Second choice: native `<dialog>` with `showModal()`, which provides focus trapping, Escape handling, background inertness, top-layer rendering, and `::backdrop` for free.
- If you must hand-roll, the contract has six clauses, all mandatory:
  1. On open, focus moves into the dialog (the first focusable control, or the dialog itself with `tabindex="-1"`).
  2. While open, Tab and Shift+Tab cycle within the dialog only — focus never reaches the background. Use the `inert` attribute on the page content behind, or a focus trap.
  3. Escape closes it (unless mid-destructive-action, in which case it asks).
  4. On close, focus returns to the element that opened it — not to `<body>`.
  5. Background scroll is locked while open (`overflow: hidden` on the scroll container, with scrollbar-width compensation if the layout shifts).
  6. `role="dialog"`, `aria-modal="true"`, and an accessible name (`aria-labelledby` pointing at the title) so screen readers announce the context switch.
- Backdrop-click-to-close: match the project's convention, but never make it the *only* close affordance — a visible close button is required.
- Render the dialog in a portal/top layer, not inside an `overflow: hidden` or transformed ancestor that will clip it.
- These requirements apply to anything claiming modality: dialogs, drawers, full-screen takeovers, lightboxes. (Non-modal popovers — menus, tooltips — have different rules; don't focus-trap those.)

**Red flags that you're about to violate this:**

- "A fixed-position div with a backdrop is a modal."
- "Focus management is a follow-up; the dialog opens and closes fine."
- "Escape handling is a nice-to-have for power users."
- "Nobody will notice the page behind still scrolls."
- "The dimmed backdrop makes it obvious you can't use the background."
- "The native dialog element is too new to rely on."

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

### Never Key React Lists by Index

NEVER use the array index as a `key` for list items that can reorder, filter, insert, or delete. Key by a stable identity from the data itself.

The key tells React which component instance owns which data across renders. Index keys mean "position is identity," so any reshape of the array reassigns every row's state — checkboxes, inputs, expansion — to the wrong record.

- Use the data's own id: `key={item.id}`, a database key, a slug, a unique field. This is the answer in roughly all cases.
- No id on the data? Look harder first (a compound of stable fields is fine: `key={`${user.id}-${role}`}`). If the data truly has no identity, generate one when the item is created — `crypto.randomUUID()` at creation/fetch time, stored on the item — never during render, and never `key={Math.random()}` (that remounts every row every render).
- Index keys are acceptable only when all of these hold: the list never reorders or filters, items are never inserted except at the end, never deleted, and rows hold no state. Static, hardcoded lists qualify. If you claim this exception, you are asserting all four — say so in a comment.
- Silencing the missing-key warning is not the goal. `key={index}` and `key={Math.random()}` both silence it while making behavior worse than the warning.
- When you encounter existing `key={index}` on a mutable list while editing, flag it; bugs from it are already latent.

**Red flags that you're about to violate this:**

- "map gives me the index right there, that's my key."
- "This makes the React warning go away, done."
- "The list probably won't be reordered."
- "There's no id field, so index is my only option."
- "Math.random() guarantees uniqueness."
- "It renders correctly, the key choice clearly works."

### Never Remove Loading and Error UI

NEVER ship or rewrite a data-driven component without explicit loading, error, and empty states. When refactoring, every state branch that existed before must exist after — restyled is fine, removed is a regression.

The happy path is one of four states. Code that only renders data works only on fast networks where nothing fails, which is no one's production.

- Before rewriting a component, inventory its current branches: loading, error, empty, partial, stale. Carry every one into the new version. If the redesign mock doesn't show them, that's a gap in the mock, not permission to delete.
- New data-driven components start from the four states, not from the data render: loading (skeleton or spinner), error (human-readable message plus a retry action where retrying makes sense), empty ("no results" with a next step), data.
- Error states must not just say something failed — render the message where the user is looking, and never let a failed fetch render the component as if there's simply no data. "Empty" and "errored" are different facts; collapsing them tells users their data is gone.
- Never let `data.something` execute before data exists; the loading branch is also your null guard.
- Async mutations (save, delete, submit) count too: a button that fires a request needs pending feedback (disabled + indicator) and a visible failure path, not fire-and-forget.
- If you genuinely intend to remove a state branch, say so explicitly in your summary so a human can veto it. Silent removal is never acceptable.

**Red flags that you're about to violate this:**

- "The design mock doesn't include a loading state, so the component doesn't need one."
- "I'll simplify by removing these conditionals — they clutter the render."
- "The API is fast, a spinner would just flash."
- "I'll handle errors in a follow-up; the happy path is the deliverable."
- "If the fetch fails, the list will just be empty, which is fine."
- "console.error in the catch block covers the error case."

### Never Win CSS Fights With !important

NEVER add `!important` to make a style apply. If your rule is losing, find out what it's losing to and fix the cascade, not the symptom.

`!important` doesn't resolve a specificity conflict — it escalates it, and every future override of that property now needs `!important` too.

- When a style doesn't apply, identify the winning rule first (devtools, or grep the codebase for the property and selector). Name the conflict before writing the fix.
- Prefer, in order: put the rule in the right layer/file so source order wins; match the existing selector's specificity exactly; use `:where()` to lower specificity of broad rules; restructure with `@layer` if the project uses it.
- Never artificially inflate selectors (`.card.card`, `div.sidebar ul li a`) to win a fight — that is `!important` in disguise and breaks just as badly.
- Acceptable uses of `!important` are narrow: utility classes explicitly designed to always win (some utility-CSS conventions), and overriding inline styles injected by third-party scripts you cannot modify. In both cases, say so in a comment.
- If you find yourself adding `!important` to beat an existing `!important`, stop — that's the arms race. Fix or flag the original instead.
- Never copy `!important` from a nearby rule "for consistency." Each instance needs its own justification.

**Red flags that you're about to violate this:**

- "My style isn't applying, !important will sort it out."
- "I don't want to touch the existing selector, so I'll just force this one."
- "It's only one property, one !important won't hurt."
- "The old rule already uses !important, so mine has to as well."
- "I'll make the selector more specific by repeating the class."
- "This is faster than figuring out where the other style comes from."

### No Direct DOM Mutation in Components

NEVER mutate DOM that the framework renders. If a component's output should change, change the state that renders it — `style`, `textContent`, `classList`, and `innerHTML` edits to framework-managed nodes are writes the next render will erase or fight.

The framework owns its tree. Manual edits create a second source of truth that survives only until the next render, which makes every such hack an intermittent bug.

- Hiding/showing, text changes, class toggles: these are render outputs. Add or change the state/prop that drives them (`{visible && <Banner/>}`, `className={isActive ? 'active' : ''}`), even when the manual edit is fewer keystrokes.
- Never locate your own elements with `document.querySelector`/`getElementById` inside a component. Use a ref. Selectors couple behavior to styling-owned class names and grab whichever match comes first, including other instances of your component.
- Refs are for the operations the framework genuinely doesn't model: `.focus()`, `.scrollIntoView()`, measuring (`getBoundingClientRect`), play/pause on media, canvas contexts. Read-and-call is fine; writing styles/content/children through a ref re-creates the original problem with better aim.
- Wrapping a non-framework library (chart, map, rich-text editor) that must own real DOM: give it a ref'd container the framework renders but never fills, initialize in an effect, destroy in cleanup, and route all updates through the library's API — never let the framework and the library both write inside that container.
- Escaping to `document.body` (modals, toasts) is what portals are for, not manual `appendChild`.
- If you find yourself mutating DOM because "the state for this is too far away," the finding is "the state is in the wrong place" — move it, don't bypass it.

**Red flags that you're about to violate this:**

- "querySelector and one style change is way less code than threading state."
- "The framework doesn't need to know about this little tweak."
- "I'll update the badge text directly, re-rendering the list is overkill."
- "classList.toggle works right now, I checked."
- "The state lives three components up, easier to just touch the DOM."
- "I'll appendChild the modal to body so it escapes the overflow."

### No Hardcoded Pixel Widths in Layouts

NEVER give a layout container a fixed pixel width or height sized to fit specific content or a specific viewport. Size layouts so content and screen dimensions drive them.

A fixed `width: 600px` works on exactly one class of screen; a fixed `height: 400px` works for exactly one length of content. Both are bugs waiting for real data.

- Containers that should fill available space: use `flex`/`grid` with `fr`, `flex-grow`, or percentages — not a pixel width that happens to match the current parent.
- Containers that should cap their growth: `max-width` (in `px`, `ch`, or `rem`), never bare `width`. `max-width: 600px; width: 100%` is the centering pattern; `width: 600px` is the broken one.
- Heights: almost never fix them. Let content define height; use `min-height` if you need a floor. If you're setting `height` to make boxes in a row match, use flex/grid alignment (`align-items: stretch`) instead.
- Don't transcribe magic numbers from a screenshot (`width: 347px`, `margin-left: 23px`). If a number has no reason, the layout system is doing the wrong job.
- Text containers: prefer `ch`/`rem` so they scale with user font-size settings; a pixel-fixed box clips text the moment someone zooms.
- If you add a fixed dimension, you must be able to say what guarantees the content fits — and "it fits the sample data" is not a guarantee.

**Red flags that you're about to violate this:**

- "The design shows the sidebar at 280px, so width: 280px."
- "I'll set the height so all the cards line up."
- "600px looks centered on my mental viewport."
- "The text fits in 340px right now."
- "I'll fix the overflow later with overflow: hidden."
- "Pixel values are more predictable than percentages."

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

### Route UI Strings Through i18n

If the project has an i18n system, NEVER hardcode a user-facing string. Every piece of text a user can see goes through the translation function — including the ones that don't feel like "content."

One hardcoded string ships English to every locale. The newest features become the most broken ones for international users.

- Before writing any UI text, check how neighboring components produce theirs. If you see `t(...)`, `<FormattedMessage>`, `$t`, or a locales directory, that's the only sanctioned path for strings.
- "User-facing" includes the easy-to-miss surfaces: placeholder text, `aria-label` and `title` attributes, validation and error messages, toast/notification text, empty states, confirm dialogs, button labels, `<option>` labels, and document `<title>`.
- Add the new key to the source-language locale file in the same change, following the project's key naming convention. A `t('untranslated.key')` rendering its raw key is just a different bug.
- Never build sentences by concatenation or naive templates (`'Delete ' + name + '?'`, `` `${n} files` ``). Use the library's interpolation (`t('confirmDelete', { name })`) and plural support (`t('fileCount', { count })`) — word order and plural rules differ across languages, so the string must stay whole inside the translation.
- Don't translate non-UI strings: log messages, error codes, analytics events, and test fixtures stay literal.
- If you cannot find the i18n setup but the repo clearly has locale files, ask rather than hardcoding "temporarily." Temporary English is permanent English.

**Red flags that you're about to violate this:**

- "It's just a button label, I'll inline it."
- "I'll hardcode for now and someone can extract strings later."
- "Placeholders and aria-labels aren't really content."
- "Template literals handle the variable, no need for i18n interpolation."
- "Adding a locale key for one string is overkill."
- "The error message comes from a throw, so it's not UI text."

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

### Stop the Z-Index Arms Race

NEVER fix a layering bug by raising a z-index above an arbitrary big number. Diagnose the stacking context first; the number is almost never the problem.

If an element with `z-index: 9999` still renders behind something, an ancestor has created a stacking context (`transform`, `opacity < 1`, `filter`, `will-change`, `position: fixed`, `isolation`), and no value will escape it.

- Before changing any z-index, identify which stacking context each competing element lives in. If they're in different contexts, compare the contexts' roots — that's where the fix goes.
- For overlays (modals, dropdowns, toasts) trapped inside a transformed ancestor, render them at the document root instead — a portal (`createPortal` in React, `Teleport` in Vue) — rather than fighting the context.
- Use the project's z-index scale if one exists (tokens, a `$z-` map, a `zIndex` theme object). If none exists, use small, ordered values (1, 10, 20...) and add a comment naming what each layer must sit above.
- Never write `z-index` greater than the highest existing value in the project without flagging that you're doing it and why.
- Never add `position: relative; z-index: N` to a parent as a blind experiment. Each new positioned, z-indexed element creates another stacking context and tightens the knot.
- If two existing layers are already in an escalation war (999 vs 9999), flag it; don't join with 99999.

**Red flags that you're about to violate this:**

- "I'll set it to 9999 to be safe."
- "Still behind? I'll add another 9."
- "I'll give the parent a z-index too, one of these will work."
- "The header is 1000, so the dropdown gets 1001, the tooltip 1002..."
- "I don't know why it's behind, but a bigger number can't hurt."
- "Max int z-index guarantees it's always on top."

### Use ARIA Sparingly and Correctly

NEVER add ARIA as decoration. No ARIA beats wrong ARIA: every role is a behavioral contract, and unkept contracts make screen reader UX worse than plain markup.

- First resort is always the native element: `<button>`, `<nav>`, `<dialog>`, `<details>`, `<select>`, `<input type=...>` carry their roles, states, and keyboard behavior built-in. Adding `role="button"` to a `<button>` or `role="navigation"` to `<nav>` is noise; *reaching for ARIA when a native element exists* is the actual bug.
- Never `aria-label` an element whose visible text already names it — it's redundant at best, and it silently overrides the visible text, drifting out of sync at the first copy change. `aria-label` is for elements with no visible text (icon-only buttons).
- A role obligates you to its whole pattern. `role="tab"` means arrow-key navigation, `aria-selected` updates, and `tabindex` roving. `aria-expanded` means the value flips when the thing expands. If you add the attribute, wire the behavior and the state updates in the same change — a hardcoded `aria-expanded="true"` is a lie told specifically to people who can't see the truth.
- Don't invent attribute names (`aria-text`, `aria-description` where you meant `aria-describedby`) and don't put roles on the wrong layer (e.g., `role="list"` styling hacks on containers whose children aren't `listitem`s).
- Dynamic announcements (`aria-live`) only where content changes out from under the user (toasts, async validation) — politely (`polite`), once, not on regions that re-render constantly.
- Justify every ARIA attribute you write in one clause: what does assistive tech gain? "It seems more accessible" is not a gain.

**Red flags that you're about to violate this:**

- "I'll add roles and labels everywhere to make it accessible."
- "aria-label can't hurt even if the text is visible."
- "role='tablist' on these divs conveys the design intent."
- "I'll set aria-expanded='true' — it's usually open anyway."
- "More ARIA is more accessible."
- "The native dialog is limited; my div with role='dialog' is equivalent."

### Use Design Tokens, Not Hardcoded CSS Values

If the project has a token system — CSS custom properties, a theme object, Tailwind config, Sass variables — NEVER write a literal where a token exists. Look up the token; don't invent the value.

Every hardcoded color and spacing literal opts that element out of theming, rebrands, and dark mode, invisibly, until the day the system changes and it doesn't.

- Before styling anything, find how sibling components get their colors/spacing/type. The project's pattern (var(--token), theme(), tw classes, $vars) is the only sanctioned source for those values.
- Colors: never write hex/rgb/hsl literals when a palette exists. Can't find a token for the color you need? That's a question for the human ("closest token is --color-warning-600 — use it, or is this a new palette entry?"), not a license to inline `#e8a13c`.
- Spacing and sizing: stay on the scale. If the scale is 4-based, 9px is wrong on purpose-shaped feet; use the scale step (or the spacing token) even when the mock measures 9. Mock pixel values are renderings of tokens, not specs for literals.
- Type: font sizes, weights, and line heights come from the type scale/text styles, not from per-component numbers.
- Don't create private lookalike variables (`--my-button-blue: #3b82f6`) shadowing the system; that's a hardcode with a token costume.
- Semantic over raw where the system offers both: `--color-danger` survives a rebrand that `--red-500` usage may not.
- Exceptions exist (a one-off marketing page, a value with no plausible token) — mark them with a comment saying why, so they're findable and intentional.

**Red flags that you're about to violate this:**

- "I know the brand blue, I'll just write the hex."
- "9px of padding matches the mock exactly."
- "Finding the right token takes longer than typing the value."
- "I'll define my own variable for this color real quick."
- "It's one gray border, hardly worth a token."
- "The nearby file uses a hex literal, so that's the convention."

### Use Real Buttons, Not Clickable Divs

NEVER attach a click handler to a `<div>` or `<span>` to make it act like a button or link. Use `<button>` for actions and `<a href>` for navigation, every time.

A div with `onClick` works only for mouse users. It has no tab stop, no Enter/Space activation, and no role announced to screen readers — the control does not exist for anyone not using a pointer.

- Action that does something on the page → `<button type="button">`. Inside a form, be explicit about `type` so you don't accidentally submit.
- If the button must not look like a button, reset the styles: `button { all: unset; cursor: pointer; }` (then restore `:focus-visible` styling). Restyling is cheap; reimplementing button semantics is not.
- Do not "fix" a clickable div by adding `role="button"` and `tabIndex={0}`. That also requires an `onKeyDown` handler for Enter and Space, plus disabled-state semantics — you are rebuilding `<button>` badly. Just use the element.
- Wrapping a whole card in a click handler: put a real `<button>` or `<a>` inside the card for the action, and expand its hit area with CSS (`::after { position: absolute; inset: 0; }`) instead of making the wrapper interactive.
- When editing existing code that already has clickable divs, flag them as bugs; do not copy the pattern for consistency.

**Red flags that you're about to violate this:**

- "A button would bring default styles I'd have to override, a div is cleaner."
- "The whole card is clickable, so the wrapper div needs the onClick."
- "I'll add role='button' and tabIndex, that makes it accessible."
- "This is just an icon, it doesn't need to be a real button."
- "The existing codebase does it this way, so I'll match the pattern."
- "It works when I click it, so the interaction is done."

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

### Write Meaningful Img Alt Text

ALWAYS make a deliberate alt decision for every image you write: either meaningful alt text, or an explicit `alt=""` for decoration. Never omit the attribute, and never fill it with filler.

Alt text is the image for non-sighted users. Lazy alt doesn't fail the build — it fails the person.

- Informative image (product photo, avatar, chart, screenshot): write what a sighted user learns from it. `alt="Line chart: signups doubled after the March launch"`, not `alt="chart"`.
- Decorative image (divider, background flourish, icon duplicating adjacent text): `alt=""` exactly, so screen readers skip it. Do not describe wallpaper.
- Functional image (logo that links home, icon-only button): describe the action, not the pixels. `alt="Back to dashboard"`, not `alt="arrow icon"`.
- Never use the filename, "image", "photo", or "icon" as alt text, and never start with "Image of" — the screen reader already announces it's an image.
- Don't blindly pass `alt={item.title}` when the title is rendered as visible text right next to the image; that reads everything twice. Use `alt=""` there.
- If you genuinely cannot know what the image shows (dynamic user uploads with no metadata), surface that as a question or use the best available data — don't invent a description.

**Red flags that you're about to violate this:**

- "I'll leave alt off for now and someone can fill it in later."
- "alt='' makes the linter pass, good enough."
- "I'll just use the filename, it's roughly descriptive."
- "This icon is small, nobody needs it described."
- "I'll write alt='decorative ornamental divider graphic' to be thorough."
- "The alt prop is required by the component, so I'll pass the title again."
