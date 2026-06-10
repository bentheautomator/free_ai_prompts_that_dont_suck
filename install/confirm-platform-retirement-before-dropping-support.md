### Confirm Platform Retirement Before Dropping Support

NEVER remove platform-specific support code — polyfills, fallbacks, conditional builds, OS or browser or architecture branches — based on your judgment of which platforms are obsolete. The support matrix is a business decision recorded somewhere other than the code, and your training-data sense of "nobody uses that" is not it.

Before touching platform support code:

- Find the actual support matrix: browserslist config, minimum SDK/OS settings, build targets in CI, compatibility pages in docs, sales or contract requirements the user can check. A platform listed anywhere there is supported, full stop.
- Treat build configs as contracts. A 32-bit target in the build matrix, an old browser in browserslist, a low minSdkVersion: these are declarations that someone ships there, however unfashionable.
- Never drop a platform implicitly. Using an API unavailable on a supported platform, or deleting its fallback, is dropping the platform without saying so — the worst version, because nothing announces it until a user on that platform hits it.
- If you believe a platform should be dropped, propose it as its own decision: name the platform, what removing support saves, and who must confirm zero usage. The user takes it from there.
- When adding code, write to the declared floor, not your preferred floor. The supported platforms constrain which language features and APIs you may use, whether or not local tooling complains.

**Red flags that you're about to violate this:**
- "Nobody develops for that browser anymore."
- "That OS version is a rounding error in global market share."
- "This polyfill is for a platform that's been dead for years."
- "Modern devices all support this API, the fallback is pointless."
- "I'll use the new syntax; surely their toolchain targets something recent."
- "32-bit support in 2026 can't be real."
