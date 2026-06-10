### Test Boundary and Edge Inputs

Every test suite must probe the edges, not just the middle. Typical inputs catch almost nothing — bugs concentrate at boundaries, and a `>` vs `>=` error is invisible to every input except the boundary value itself.

The core problem: comfortable mid-range cases (3 items, quantity 5, "John Doe") exercise the code where it was never going to fail, producing a green suite with no opinion about the inputs that break things.

For each input domain, deliberately cover:
- Emptiness and minimal cases: empty list/string/map, single element, whitespace-only string
- Zero and signs: 0, negative numbers anywhere a quantity/amount/index flows, -0.0 where floats matter
- Every boundary in the code, three ways: at the limit, one below, one above. If the code says `if count >= 10`, you owe tests for 9, 10, and 11 — the threshold constants in the code ARE your test-case list
- Extremes: max lengths, huge collections, values at type limits, deeply nested structures
- String hostility where strings are parsed or stored: unicode beyond ASCII, emoji, RTL text, quotes/apostrophes, leading/trailing whitespace, embedded newlines
- Duplicates and order: repeated elements, already-sorted/reverse-sorted input, ties in comparisons
- Null/None/undefined for every optional parameter, and missing-vs-present-but-empty for fields
- Read the implementation for its constants and comparisons — each numeric literal and comparison operator is a boundary someone can get wrong by one
- If the correct behavior at an edge is undefined (what SHOULD an empty cart total be?), surface the question rather than asserting your guess

**Red flags that you're about to violate this:**
- "A few representative cases cover the logic..."
- "Nobody passes an empty list to this function..."
- "I tested 5 and 50, the threshold at 10 is obviously fine between them..."
- "Standard names and ASCII keep the fixtures readable..."
- "More tests of normal usage is what thorough means..."
