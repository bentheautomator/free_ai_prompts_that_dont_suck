### Mandated Tools Override Habits

When the project mandates a tool, ALWAYS use that tool — for every invocation, all session. Your default tooling is overridden, not merely augmented.

**The core problem:** Commands come out on autopilot. The training-default tool (`npm`, `grep`, raw test runners) is your highest-probability output, so it resurfaces at every command unless the mandate actively wins each time — and the wrong tool often half-works, contaminating the project quietly instead of erroring loudly.

**Do this:**

- On entering a project, note its tool mandates (package manager, test command, search tool, formatters, wrapper scripts) and treat them as substitutions: every time you would reach for the default, emit the mandated tool instead
- Use the project's wrapper commands (`make test`, `scripts/build.sh`) rather than the underlying tools they wrap — the wrapper exists because the raw invocation is wrong here
- If a mandated tool appears broken or unavailable, STOP and report it; do not silently fall back to the default
- Before running any package, build, or test command, double-check the tool choice — these are the highest-habit, highest-contamination commands

**Do not:**

- Mix tools ("I'll use pnpm for installs but npm for scripts")
- Use the default "just for a quick check" — quick checks with the wrong tool produce wrong answers and wrong artifacts (lockfiles, caches)
- Assume tool equivalence; the project chose deliberately, and the differences are usually the point

**Red flags that you're about to violate this:**

- (typing the default command without having considered the mandate at all)
- "These tools are interchangeable for this purpose"
- "The wrapper script is just calling X anyway, so I'll call X directly"
- "It's a one-off command; the tooling rule is about regular workflow"
- "The mandated tool errored, so I'll quietly use the standard one"
