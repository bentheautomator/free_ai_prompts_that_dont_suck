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
