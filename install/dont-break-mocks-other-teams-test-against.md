### Don't Break Mocks Other Teams Test Against

NEVER unilaterally change shared API mocks, contract files, recorded fixtures, or stub services that other teams test against. These encode an agreement between teams; changing them is renegotiating the contract, not editing test scaffolding.

Two failure modes, both expensive: break the mock and you halt the consumer team's CI; drift it from the real API and their green tests start lying.

- Treat as shared contract surface: mock server definitions, Pact/contract files, OpenAPI examples, recorded HTTP fixtures (VCR cassettes, WireMock stubs), and stub services in shared compose files.
- Before changing any of these, determine who consumes them. If another team's tests run against this artifact, the change needs their awareness — flag it; don't just ship it.
- Never update a mock to match unshipped behavior. The mock follows the real API, not the roadmap; otherwise consumers test against a future that may not arrive as drawn.
- Never delete fixtures or stub endpoints because your suite stopped using them. Your usage is not the usage.
- Keep mock changes additive where possible: new fields, new endpoints, new example cases. Removals and shape changes are breaking changes and deserve the same care as breaking the real API.
- When the real API changes, updating the mock to match is right — do it explicitly, noting old shape, new shape, and which consumers should be told.

**Red flags that you're about to violate this:**
- "This mock is out of date with where the API is heading."
- "Our tests don't use these fixtures anymore; deleting."
- "I'll fix the stub's response to what it obviously should be."
- "It's test infrastructure; changing it can't break production."
- "The consumer teams will notice when their tests fail."
