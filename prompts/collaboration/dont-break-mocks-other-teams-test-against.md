---
title: Don't Break Mocks Other Teams Test Against
slug: dont-break-mocks-other-teams-test-against
category: collaboration
tags: [universal, teamwork, contracts]
works_with: all
severity: high
one_liner: "Stops changes to API mocks and contract stubs other teams build against"
---

# Don't Break Mocks Other Teams Test Against

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing shared API mocks, contract fixtures, and stub servers that other teams' test suites depend on.

**[Copy-paste ready version](../../install/dont-break-mocks-other-teams-test-against.md)** — just the instruction block, no explanation.

## The Problem

Between teams that integrate, there's usually a layer of agreed pretend: a mock server for the payments API, recorded response fixtures, contract files (Pact, OpenAPI examples), a stub service in docker-compose that stands in for another team's system. Consumer teams develop and test against this layer daily. The AI, working on the provider side or just tidying test infrastructure, changes it: updates a mock's response shape to match a new idea of the API, deletes "stale" recorded fixtures, changes a stub's port or endpoints, regenerates examples from a draft spec. Its own tests pass. The other team's entire suite goes red — or worse, the AI changed the mock to match behavior the real API doesn't have yet, and the consumer team builds against fiction.

Both failure directions are nasty. Break the mock and you've halted another team's development on infrastructure they don't own and can't quickly fix. Drift the mock from reality and you've poisoned their tests' meaning: everything passes against the stub, then integration fails in staging — or production — where the real service disagrees with the pretend one. A shared mock is a treaty document; editing it unilaterally is renegotiating the treaty without telling the other signatory.

The AI does this because mocks look like test scaffolding, and test scaffolding reads as freely editable. Nothing in the files says "another team's CI runs against this 400 times a day."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reclassifies mocks from scaffolding to treaty** — the AI's "it's just test code" heuristic is precisely wrong here, because the artifact's whole purpose is to be depended on by people elsewhere.
2. **It pins the mock to shipped reality**, blocking the drift failure where consumer tests verify an API that doesn't exist and integration becomes the first real test.
3. **It applies breaking-change discipline to pretend APIs**, because a consumer's CI can't tell the difference between the real service breaking and the stand-in breaking.
4. **It separates "my suite's usage" from "all usage,"** the same fan-in blindness that kills shared helpers, applied to fixtures.

## Origin

A provider team's assistant regenerated the shared mock server from a draft of the v2 spec — renamed fields, new envelope — reasoning the mock should "lead" the migration. The consuming mobile team's CI stayed green: their code was updated to match the mock. The v2 rollout then slipped a quarter. The mobile team shipped a release built against an API shape that existed only in the mock, and every list screen in the app rendered empty against the real v1 service. The hotfix took a weekend; the trust took longer.
