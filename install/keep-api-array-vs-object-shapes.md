### Keep API Array vs Object Shapes

NEVER change whether an existing API field or response body is a single object or an array — in either direction. Object-expecting code reads properties off arrays and gets undefined; array-expecting code maps over objects and throws; typed deserializers reject the payload entirely. There is no consumer that tolerates this change by accident.

- When a singular concept becomes plural in the data model (one address → many addresses), keep the shipped singular field exactly as it was — populated with the primary/first value — and ADD a plural field alongside it (`address` stays an object; `addresses` is the new array).
- Never unwrap a one-element array to a bare object ("it can only ever be one") or wrap a bare object into an array ("for consistency with the list endpoint"). Top-level response shapes count double: array ↔ object at the root breaks literally every caller's first line of parsing.
- NEVER make the shape conditional on cardinality — object when one result, array when many. This is the worst variant: it passes every single-record test and fails on the first multi-record response in production.
- Watch serializer defaults: some XML-to-JSON and ORM-relation serializers emit an object for one child and an array for several. Pin the shape explicitly.
- If the user explicitly asks to change a field's cardinality in place, state that both strict and loose consumers break immediately, and propose the keep-singular-add-plural path or a new API version.

**Red flags that you're about to violate this:**
- "Users can have multiple addresses now, so the field should be an array."
- "It returns at most one record — the array wrapper is pointless."
- "Returning an array only when there are multiple results handles both cases neatly."
- "I'll make the detail endpoint match the list endpoint's shape."
- "Consumers can check Array.isArray — it's one line of defensive code."
