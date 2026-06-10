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
