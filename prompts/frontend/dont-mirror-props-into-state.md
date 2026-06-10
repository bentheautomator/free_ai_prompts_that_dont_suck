---
title: Don't Mirror Props Into State
slug: dont-mirror-props-into-state
category: frontend
tags: [universal, frontend, react]
works_with: all
severity: high
one_liner: "Stops useState(props.value) copies that freeze at first render"
---

# Don't Mirror Props Into State

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from initializing state from props, creating a frozen copy that ignores every parent update after the first render.

**[Copy-paste ready version](../../install/dont-mirror-props-into-state.md)** — just the instruction block, no explanation.

## The Problem

`const [user, setUser] = useState(props.user)` looks like a reasonable line, and AI assistants write it constantly. What it actually means: take a snapshot of the prop at first mount, then ignore the prop forever — `useState`'s initializer runs once. The parent refetches, the prop updates, the child keeps rendering the stale copy. The bug report reads "the panel doesn't update until I refresh," and it reproduces only when the prop changes after mount, which is precisely the case the AI's first-render evaluation never covers.

The AI then often "fixes" its own bug with the patch that makes everything worse: `useEffect(() => setUser(props.user), [props.user])` — a manual re-implementation of what reading the prop directly would do for free, plus an extra render per change, plus a window where state and prop disagree, plus the question of what happens to local edits when the sync clobbers them (answer: they vanish mid-edit).

The pattern usually originates from a half-real need: the component lets the user *edit* the value, so it needs somewhere to hold the draft. The mistake is not noticing that this makes the component's relationship to the prop a design decision — controlled (parent owns the value) or uncontrolled-with-initial-default (snapshot is intentional, reset via `key`) — and instead landing in the accidental middle: a copy that's neither.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It states the one-shot initializer fact plainly.** The bug exists because `useState(props.x)` *reads* like a live binding; knowing the initializer runs once makes the line look as wrong as it is.
2. **It bans the sync-effect by name with the reason attached.** That effect is the AI's reflexive self-fix, and only an explicit "this is the wrong design, not a patch" stops the second mistake from burying the first.
3. **It legitimizes the real use case with a naming contract.** Draft-editing genuinely needs the snapshot; routing it through `initialValue` + `key` keeps the pattern available while making accidental copies distinguishable from intentional ones.
4. **It poses the ownership question as a fork.** "Who wins when the prop changes mid-edit?" has only two coherent answers, and forcing the choice prevents the incoherent middle state that generates the bugs.

## Origin

A CRM's contact-detail drawer took the contact as a prop and copied it into state for rendering. When users edited a contact in the main table, the drawer — already open — kept showing the old data, and saving from the drawer wrote the stale copy back over the fresh edit. Users called it "the app that undoes my changes." The assistant's first fix was the sync-effect, which then discarded in-progress drawer edits whenever background refetch ran. The real fix deleted the state entirely for display fields and moved the editable ones to `initialValue` + `key={contact.id}`.
