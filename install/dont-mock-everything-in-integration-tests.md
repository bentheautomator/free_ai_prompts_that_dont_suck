### Don't Mock Everything in Integration Tests

NEVER mock away so many collaborators that a test no longer exercises any real interaction between real components. Before adding each mock, name what the test still verifies if the mock goes in — and stop when the answer approaches "that the mocks get called."

The core problem: every mock replaces a seam where real components could disagree with a stub that always agrees. Mock all the seams and the test can no longer fail for any reason that matters.

Rules:
- Decide the test's integration boundary explicitly and state it: which real components talk to each other, and where the world is faked. "Service + real repository + in-memory DB, with the external payment API faked" is a boundary; "mock whatever errors" is not
- Mock at the system's edges (third-party APIs, payment processors, email), not between your own components — inter-component contracts are the thing integration tests exist to check
- Prefer real-ish substitutes over interaction stubs: in-memory or containerized databases, the framework's test client/server, fakes with actual behavior (a real in-memory queue) rather than `mock.calledWith` choreography
- When a dependency errors in test setup, the first option is to provide it (test container, fixture, in-process fake), not to stub it. Stubbing-on-error is how integration tests dissolve one mock at a time
- If the environment truly can't support the real dependency, say so and ask, rather than silently downgrading the test's meaning while keeping its name
- Honesty rule: a test where every collaborator is mocked is a unit test. Name it as one or rebuild it

**Red flags that you're about to violate this:**
- "The DB isn't available here, I'll mock the repository too..."
- "Mocking all the services makes this test fast and reliable..."
- "It still tests the flow — each step is verified to be called..."
- "One more mock won't change what the test covers..."
- "I'll mock it now so the test runs, and it can be made real later..."
