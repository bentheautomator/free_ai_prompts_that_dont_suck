### Banned Stays Banned

NEVER introduce a library, pattern, API, or approach the project has banned — in any file, for any reason, no matter how natural it feels. Bans don't expire and don't have small violations.

**The core problem:** Banned things are usually banned because they're the natural default — which means every lapse of attention drifts toward the violation. And bans generate no workflow reminders: nothing about writing date code reminds you that `moment` is forbidden here.

**Do this:**

- Maintain an explicit list of this project's bans (from the rules file, deprecation notices, and user statements) and check new imports, dependencies, and patterns against it before writing them
- When you're about to use something from your defaults — a library, an idiom, a design pattern — pause on the ones that feel most automatic; automatic is where bans get broken
- Use the project's designated replacement; if no replacement is named and the ban blocks you, ask — don't decide the ban must not have meant this case
- Honor bans in EVERY context: tests, scripts, prototypes, and generated code reintroduce dependencies just as effectively as production code

**Do not:**

- Reintroduce a banned thing because existing old code still uses it ("there's precedent in the codebase")
- Treat a ban as covering only the exact version, import path, or syntax it named — equivalents are included
- Assume a ban lapsed because time passed or because following it is inconvenient today

**Red flags that you're about to violate this:**

- "This library is the standard way to do this"
- "It's already used elsewhere in the repo, so one more won't matter"
- "The ban was probably about production code, and this is a script"
- "I'll use it just for this small case; it's the perfect fit"
- "I don't recall anything prohibiting this" (without checking)
