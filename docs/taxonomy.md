# Prompt Taxonomy

The category map for this repo. Every prompt lives in exactly one category, and every category has a charter: what failure domain it owns and what it explicitly does *not* cover. When two categories could plausibly claim a prompt, the charter's exclusion rules break the tie.

If you're adding a prompt and none of these fit, create a new directory — the build script discovers categories automatically. But read the charters first; "none of these fit" is usually wrong.

## Category Charters

| Category | Owns | Does NOT Own |
|----------|------|--------------|
| `agents-and-automation` | Long-running agent sessions: runaway loops, tool misuse, context decay, subagent handoffs, autonomous overreach | One-shot instruction compliance (`instruction-following`) |
| `api-design` | Contracts and compatibility: breaking changes, versioning, pagination, error shapes, REST/GraphQL/RPC discipline | Server implementation details (`backend`) |
| `architecture` | Boundaries and layering: premature abstraction, circular dependencies, god objects, framework misuse | Single-function code quality (`code-quality`) |
| `backend` | Services and servers: idempotency, queues, timeouts, background jobs, webhooks | API contracts (`api-design`), SQL (`databases`) |
| `ci-cd` | Pipelines: skipping checks, flaky-test band-aids, build caching, release automation | Infra and deploys (`devops`), test content (`testing`) |
| `code-quality` | Edit correctness: hallucinated APIs, pattern violations, style drift, copy-paste rot, dead code | Destructive actions (`code-safety`), system design (`architecture`) |
| `code-review` | PR hygiene: diff size, self-review, responding to feedback honestly, review etiquette | Git mechanics (`git`) |
| `code-safety` | Destructive and irreversible actions outside git and databases: file deletion, overwrites, prod systems, bulk operations | Git operations (`git`), SQL/data (`databases`) |
| `collaboration` | Shared-codebase citizenship: conventions, ownership, not breaking teammates, merge etiquette | PR review mechanics (`code-review`) |
| `communication` | Telling the user what's happening: silent changes, burying the lede, fake confidence, asking good questions | Proving claims with evidence (`verification`) |
| `concurrency` | Races, deadlocks, async/await misuse, shared state, ordering assumptions | General performance (`performance`) |
| `configuration` | Env vars, config sprawl, environment confusion, feature flags, dangerous defaults | Secrets handling (`security`), deploy configs (`devops`) |
| `context` | Grounding in reality: hallucinated paths, stale assumptions, ignoring repo conventions, unverified versions | Communicating uncertainty (`communication`) |
| `databases` | Migrations, destructive SQL, ORM pitfalls, prod data, indexes, transactions | App-level data structures (`code-quality`) |
| `debugging` | Root-cause discipline: guess-and-check fixes, symptom patching, not reproducing first, ignoring stack traces | Claiming fixes work (`verification`) |
| `dependencies` | Adding/upgrading/removing packages: lockfiles, pinning, supply-chain hygiene, license awareness | CVE remediation in code (`security`) |
| `devops` | Infra and deploys: containers, IaC, environments, rollbacks, monitoring, DNS/TLS | Pipeline logic (`ci-cd`) |
| `documentation` | Stale docs, comment noise, README drift, changelog discipline | Code comments as a quality issue (`code-quality`) |
| `error-handling` | Swallowed exceptions, catch-all handlers, silent fallbacks, retry logic, partial failure | User-facing error UX (`frontend`) |
| `file-handling` | File operation hygiene: encoding, line endings, generated files, paths, temp files, formatting churn | Deleting files (`code-safety`) |
| `frontend` | UI work: accessibility, state management, CSS hacks, responsive breakage, hydration, i18n | API consumption contracts (`api-design`) |
| `git` | Commits, branches, history, merge/rebase, push safety, .gitignore, stashes | PR descriptions and review (`code-review`) |
| `instruction-following` | Obeying user rules: skipping, partial compliance, forgetting mid-session, reinterpreting | Staying on task scope (`scope`) |
| `language-pitfalls` | Language-specific traps: Python mutability, JS equality, Go nil, Rust ownership, type coercion | General code quality (`code-quality`) |
| `legacy-code` | Touching old code: Chesterton's fence, modernization restraint, dead-looking code, compatibility | Refactoring mechanics (`refactoring`) |
| `performance` | Premature optimization, N+1 queries, unmeasured claims, memory leaks, caching mistakes | Concurrency primitives (`concurrency`) |
| `planning` | Plan-before-code, task breakdown, sequencing, knowing when to stop and think | Scope discipline (`scope`) |
| `refactoring` | Behavior-preserving change discipline: big-bang rewrites, rename fallout, mixing refactors with features | Whether to refactor at all (`scope`, `legacy-code`) |
| `scope` | Doing only what was asked: feature creep, over-engineering, drive-by edits, gold-plating | Following explicit rules (`instruction-following`) |
| `security` | Secrets, injection, authn/authz, unsafe defaults, crypto misuse, PII | Package hygiene (`dependencies`) |
| `testing` | Writing and maintaining tests: deleting failing tests, weakening assertions, over-mocking, coverage theater | Proving non-test work correct (`verification`) |
| `verification` | Proving work is done: claiming success without running code, "should work," fake completion, smoke-test discipline | Test authoring (`testing`) |
| `data-and-ml` | Pipelines, notebooks, model code, eval honesty, data leakage, reproducibility | Database operations (`databases`) |

## Severity Distribution

Severity is assigned per the SOP guide (`docs/SOP-delivery.md`): `critical` for data loss / security / hours of lost work, `high` for bugs and broken code, `medium` for friction and inconsistency. A healthy category has a mix — if everything in a category is `critical`, the word means nothing.

## Naming

- Slugs are imperative and specific: `never-edit-generated-files`, not `file-stuff`.
- Slugs are globally unique across all categories — the build fails on collisions, because `install/<slug>.md` is keyed by slug alone.
- Category names are lowercase-kebab-case.
