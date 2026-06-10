---
title: Keep Mocks Matched to Real Interfaces
slug: keep-mocks-matched-to-real-interfaces
category: testing
tags: [universal, testing, mocking]
works_with: all
severity: high
one_liner: "Hand-rolled mocks drifting from the real API until tests pass on fiction"
---

# Keep Mocks Matched to Real Interfaces

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents mocks that accept calls and return shapes the real dependency never would.

**[Copy-paste ready version](../../install/keep-mocks-matched-to-real-interfaces.md)** — just the instruction block, no explanation.

## The Problem

A loose mock is a yes-man. `jest.fn()` and bare `MagicMock()` will accept any method name, any argument count, any typo, and cheerfully return another mock. So when the AI writes a test where the code calls `client.fetch_user(id, include_profile=True)` and the real client's signature is `fetch_user(user_id)`, nothing complains — the mock takes whatever it's given. The test passes; production throws `TypeError: unexpected keyword argument`. Same story for return shapes: the AI stubs `getUser` to return `{ name, email }` because that's what the test needs, while the real API returns `{ data: { attributes: { name, email } } }` — the test passes against a structure that exists nowhere outside the test file.

This is how mock drift happens, and AI assistants accelerate it because they write mocks from what the *consuming code* expects rather than from what the *dependency* provides — often without ever opening the dependency's actual interface. The mock is then evidence of nothing except the test's internal consistency. When the real API changes a signature in v3, every hand-rolled mock keeps simulating v2, and the suite stays green straight through the breaking upgrade.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reverses the derivation direction.** The AI builds mocks from the consumer's expectations — the one source guaranteed to agree with the code under test. Mandating derivation from the dependency's side restores the independent reference the mock was supposed to be.

2. **It delegates enforcement to machinery.** `autospec`, `spec=`, and typed mocks turn interface drift from a discipline problem into a hard error the AI cannot miss. The rule mostly consists of switching on verification that already exists.

3. **It treats unknown interfaces as blockers, not blanks.** The worst drift starts with a guessed method name. Making "I can't find the real signature" a stop condition prevents fiction from entering the suite with a green stamp.

## Origin

A service migrated its payment SDK from v2 to v3, which renamed `charge(amount, currency)` to `createCharge(options)`. The team's 40-odd payment tests all passed after the upgrade — every one used a bare mock that accepted any method call, all hand-written by an assistant from the consuming code's perspective. The first real transaction after deploy threw `charge is not a function`. Checkout was down for 90 minutes while everyone stared at a wall of green tests simulating an SDK that no longer existed.
