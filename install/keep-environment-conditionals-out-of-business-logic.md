### Keep Environment Conditionals Out of Business Logic

NEVER branch on the environment name (`if env == "production"`) inside application code. Express the difference as a named config value — a capability — and let per-environment config set it. Business logic asks `config.email_sending_enabled`, never `env == "prod"`.

Scattered env-name checks turn "what does staging do?" into a grep-and-simulate exercise, and every new environment mis-sorts through all of them simultaneously.

- When you're about to write an environment check in app code, name the behavior it controls instead: `send_real_emails`, `payments_live_mode`, `strict_cors`. Add that key to the config layer, set it appropriately per environment, and branch on the key.
- The environment name should be consumed in approximately one place: the config loader that selects which value-set to apply. If `APP_ENV` is read anywhere else, that's the smell.
- Don't enumerate environments in logic (`env in ["staging", "production"]`) — the list is stale the day someone adds an environment, and it fails silently for the new one.
- When working in code that already has env conditionals, don't add siblings. Match the task's scope: introduce the capability key for your change, and flag the neighbors for conversion.
- Capabilities also make the safety default explicit: a new environment with no config gets the key's declared default (choose the safe one), instead of whatever side of a string comparison it happens to land on.

**Red flags that you're about to violate this:**
- "It's just one if-statement, a config key is ceremony."
- "This behavior is inherently about production, checking the name is honest."
- "There are already env checks in this file, I'm being consistent."
- "We only have three environments, the enumeration is fine."
- "I'll check `env != 'development'` so it's safe everywhere else."
