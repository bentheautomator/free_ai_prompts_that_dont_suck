---
title: No Invented Config Options
slug: no-invented-config-options
category: code-quality
tags: [universal, config]
works_with: all
severity: high
one_liner: "AI inventing plausible-looking config keys that the tool silently ignores"
---

# No Invented Config Options

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing configuration keys that look right but don't exist, and that tools silently ignore.

**[Copy-paste ready version](../../install/no-invented-config-options.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "make webpack cache builds" and you might get `cache: { strategy: 'aggressive' }` — a setting that has never existed. Ask for stricter TypeScript and you might get `"strictNullHandling": true` in tsconfig instead of `"strictNullChecks"`. Config schemas are the perfect hallucination substrate: they're key-value soup, every tool's options look like every other tool's options, and the model fills gaps with whatever sounds idiomatic.

What makes this failure especially expensive is that most tools don't validate unknown keys. Webpack, many ESLint setups, docker-compose with loose schemas, YAML-driven CI systems — they shrug and ignore what they don't recognize. There's no error, no warning, nothing. The user believes caching is on, the timeout is raised, the rule is enforced. It isn't. The invented option sits in the config file radiating false confidence, sometimes for months, until someone profiles the build or audits the security settings and discovers the knob was never connected to anything.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Invented Config Options

NEVER write a configuration key you haven't verified against the tool's actual schema or documentation. Config files are where hallucinations go to hide, because most tools silently ignore unknown keys instead of erroring.

A made-up option doesn't fail loudly. It just does nothing while everyone believes it's working — fake caching settings, fake security flags, fake timeouts.

**Before adding or changing any config option:**
- Verify the exact key name and value type against the tool's documentation, JSON schema, or typed config definitions for the version in use
- Check existing config files in this project for how similar options are spelled and nested — nesting errors (right key, wrong level) are as fatal as wrong keys
- If the tool offers validation (`tsc --showConfig`, `eslint --print-config`, schema-validated YAML, `--check`/`--dry-run` flags), run it after editing
- Never blend option names across similar tools — Jest options into Vitest config, npm fields into pnpm, GitLab CI keys into GitHub Actions
- If you cannot verify a key exists, say so instead of writing your best guess into a file nobody will question

**Red flags that you're about to violate this:**
- "A tool like this would definitely have an option for..."
- "The naming convention suggests the key would be called..."
- "This is how the similar tool spells it, so..."
- "I'll set this to true — that's usually what it's called..."
- "The exact name might differ slightly, but this should work..."
- Writing a config key you've never seen in this project's files or the tool's docs

---

## Why It Works

1. **It names the silent-failure mechanism.** The AI treats config edits as low-risk because nothing crashes. Stating that unknown keys are *ignored*, not rejected, reframes config as the highest-stakes place to guess, not the lowest.

2. **It targets nesting, not just spelling.** Half of real config failures are correct keys at the wrong depth. Calling that out separately closes a loophole that "verify the key name" alone leaves open.

3. **It blocks cross-tool contamination.** Jest-into-Vitest and Travis-into-Actions blending is the literal generative mechanism of this failure. Naming the pattern lets the AI catch itself mid-blend.

4. **It mandates machine verification where it exists.** `--print-config` style commands turn "I think this is right" into a check that takes two seconds and lies to no one.

## Origin

An engineer asked for response compression on a reverse proxy. The AI added a compression block with a key that belonged to a different proxy entirely; the server parsed the file, ignored the unknown section, and started cleanly. Monitoring dashboards were updated to celebrate the bandwidth win that never came. The fiction survived four months until a CDN bill review revealed transfer sizes hadn't moved a byte.
