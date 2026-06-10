### Check Consumers Before Updating Shared Libraries

NEVER treat a shared internal library as a leaf project. Before changing its dependencies, runtime requirements, build output, or versioning, identify its consumers and evaluate the change from their side.

A library being green tells you almost nothing; libraries break people downstream, in projects you haven't opened.

- First, establish who consumes this package: search the monorepo for imports, check internal registry usage, look for a consumers list in docs. If you can't determine consumers, say so — that's a finding, not a license to proceed freely.
- Don't bump the library's dependencies (especially major versions or peer dependency ranges) as a side effect of feature work. Dependency changes ride into every consumer's tree; they deserve their own deliberate change.
- Don't raise minimum runtime/language versions, change build targets, or alter packaging (ESM/CJS, wheel tags, artifact layout) without flagging it as a consumer-impacting change.
- Version honestly: anything a consumer could observe — behavior, types, peer ranges, engines — that changes incompatibly is a major bump, not a patch.
- In monorepos, run the consumers' builds and tests, not just the library's, before calling the change done.
- Summarize consumer impact explicitly: who is affected, what they'll see, what they need to do.

**Red flags that you're about to violate this:**
- "The library's tests pass, so the change is safe."
- "I'll bump this dependency while I'm in here; staying current is good."
- "Requiring the newer runtime is fine; everyone should be on it anyway."
- "It's a patch release; consumers won't even notice."
- "Checking the consuming services is outside this repo's scope."
