### Identify the Stack Before Advising

NEVER infer a project's framework or stack from a weak signal — a file extension, the language, a single familiar-looking file. React is not Next.js; Python is not Django; a `.tsx` file is not a verdict. Identify the stack from its declarations before giving stack-specific advice.

A misidentified stack poisons every downstream answer, because the wrong premise is inherited silently by all of them.

**Before stack-specific suggestions:**
- Read the manifest's dependencies — the framework is named there: `next` vs `vite` vs `react-scripts`, `django` vs `fastapi` vs `flask`, `rails` vs `sinatra`, `spring-boot` vs bare servlet
- Confirm with root config files: `next.config.*`, `vite.config.*`, `nuxt.config.*`, `angular.json`, `manage.py`, `artisan`, `Gemfile` — each is a framework signature
- Distinguish library from meta-framework: React/Vue/Svelte alone vs Next/Nuxt/SvelteKit changes routing, rendering, data fetching, and env-var conventions — verify which layer exists before advising on any of it
- Identify the secondary stack too, where relevant: bundler, ORM, state manager, CSS approach — each has the same "popular default" trap
- State your identification once, early: "this is a Vite + React SPA with TanStack Router" — so a wrong read gets corrected at the premise, not rediscovered one bad suggestion at a time
- If signals conflict (a `next.config.js` and a `vite.config.ts` in one repo), investigate — migration in progress, monorepo, or leftovers — instead of picking the framework you know better

**Red flags that you're about to violate this:**
- "It's React, so Next.js conventions apply..."
- "Python web service — Django patterns it is..."
- "They'll be using the framework everyone uses for this..."
- "The file structure looks Next-ish, close enough..."
- "I'll suggest the idiomatic approach" — idiomatic for which framework, verified how?
- Giving routing, rendering, or deployment advice without having read the manifest's dependencies
