---
title: Key CI Caches on Real Inputs
slug: key-ci-caches-on-real-inputs
category: ci-cd
tags: [universal, ci]
works_with: all
severity: high
one_liner: "Stops the AI from writing cache keys that serve stale builds as fresh ones"
---

# Key CI Caches on Real Inputs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from configuring CI caching with keys that don't change when the cached content should, so stale dependencies and build outputs masquerade as current.

**[Copy-paste ready version](../../install/key-ci-caches-on-real-inputs.md)** — just the instruction block, no explanation.

## The Problem

CI caching has one hard problem and it's the famous one: invalidation. A cache key like `key: deps-cache-v1` or `key: ${{ runner.os }}-node` never changes, so the cache never invalidates, so every run restores whatever was saved the first time — old dependency trees, stale compiled objects, last month's tool versions. The pipeline gets faster and stops testing what you think it tests. You bump a dependency in the lockfile; CI restores the cached `node_modules` over it; tests pass against the old version; production runs the new one.

The cruelest property of a bad cache key is that the failure is asymmetric: it never makes CI red. It makes CI green for the wrong reasons, which means the feedback loop that would normally catch a config mistake is exactly the thing the mistake disables. Teams typically discover stale caches during an outage, when "but it passed CI" turns out to mean "it passed against an environment from March."

Assistants produce bad keys because caching examples float around with placeholder keys, and because when a cache step errors, the path of least resistance is to simplify the key until it stops erroring — usually by removing the `hashFiles()` part that made it correct. Caching also feels like pure optimization, so it gets none of the suspicion a test change would.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Key CI Caches on Real Inputs

ALWAYS construct CI cache keys from a hash of the files that determine the cached content, and NEVER cache something whose staleness CI can't detect. A cache with a static key is not an optimization; it's a time capsule that your tests run against instead of your code.

- Dependency caches must key on the lockfile: `key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}`, and equivalently `poetry.lock`, `Cargo.lock`, `go.sum`, `Gemfile.lock`. If the lockfile changes and the key doesn't, the key is wrong.
- Use `restore-keys` prefixes only for partial-match fallback where the job rebuilds on top of the restored content (e.g., compiler caches). Never use a fallback for content the job treats as authoritative, like an installed dependency tree it won't reinstall.
- Never cache build outputs, test results, or anything the pipeline exists to produce and verify. Caching the thing you're measuring is measuring the cache. Use artifacts for passing outputs between jobs — artifacts are tied to the run; caches leak across runs.
- When a cache-related step misbehaves, fix the key expression — do not "simplify" the key by dropping the hash, and do not solve it by caching more aggressively.
- If you suspect a stale cache is masking a failure, bump a version prefix in the key (`v1-` to `v2-`) to force a cold run and verify the pipeline still passes from scratch. A pipeline that only passes warm is broken.
- Include the toolchain in the key when the cached content is toolchain-specific (Python minor version, compiler version), or restored content will silently mismatch the runtime.

**Red flags that you're about to violate this:**

- "A static key means more cache hits, which means faster CI."
- "The hashFiles expression is what's erroring, so I'll just remove it."
- "Caching the build output will save us the whole compile step."
- "The cache is probably fine; nobody's complained."
- "I'll cache node_modules directly so we can skip npm install entirely."

---

## Why It Works

1. **It states the invariant instead of a recipe**: key = hash of determining inputs. That generalizes across ecosystems and survives the assistant meeting a CI system the examples didn't cover.
2. **It names the asymmetry.** Bad caching never fails red, so the assistant's usual feedback signal is absent; the rule substitutes an explicit verification move (cold-run via key bump) for the missing signal.
3. **It draws the cache/artifact line on lifetime semantics** — caches outlive runs, artifacts don't — which is the actual reason caching pipeline outputs corrupts the measurement.
4. **It anticipates the degradation path** (error in key expression, then hash removed, then key static) and blocks the specific second step where correctness is usually lost.

## Origin

A workflow cached `node_modules` under the key `deps-${{ runner.os }}` after an assistant "fixed" a hashFiles syntax error by deleting the hash. For seven weeks, every CI run tested against the dependency tree from the day the cache was first saved — including through a security upgrade of the HTTP client that the lockfile recorded and the cache ignored. The upgrade that "passed all tests" broke request signing in production within an hour of deploy, because production was the first environment to actually install it.
