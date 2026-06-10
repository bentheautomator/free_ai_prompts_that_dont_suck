### Keep Mocks Matched to Real Interfaces

ALWAYS derive a mock from the real dependency's actual interface, and use spec-enforcing mock features wherever the framework has them. A mock that accepts calls the real object would reject is testing a fiction.

The core problem: permissive mocks (`MagicMock()`, bare `jest.fn()`) say yes to everything — wrong method names, wrong signatures, impossible return shapes — so the test passes while the code would fail against the real dependency on the first call.

Rules:
- Read the real interface before mocking it. The mock's methods, signatures, and return shapes come from the dependency's code or docs — not from what your test happens to need
- In Python, use `autospec`/`spec` always: `mock.patch("svc.Client", autospec=True)` or `MagicMock(spec=Client)` — these raise on nonexistent attributes and wrong signatures. A bare `MagicMock()` for a known class is a defect
- In typed ecosystems, type the mock against the real interface (`jest.mocked(client)`, `MockProxy<Client>`, implementing the interface) so the compiler rejects drift
- Build stub return values from the dependency's real response shape — including envelope/nesting (`{data: {...}}`), field casing, and error formats. Copying a real sample response into the fixture beats inventing one
- When the dependency is upgraded or its API changes, hand-rolled mocks are part of the change's blast radius: update them deliberately, and say so
- If you can't find the real interface to copy, that's a stop-and-check moment — guessing a signature into a mock bakes the guess into a permanently passing test

**Red flags that you're about to violate this:**
- "MagicMock will accept whatever the code calls, that's convenient..."
- "I'll shape the stub response around what the function needs..."
- "I don't have the client's source handy, the method is probably called fetchUser..."
- "autospec is slower and stricter than I need here..."
- "The mock worked for the other tests, I'll reuse the pattern..."
