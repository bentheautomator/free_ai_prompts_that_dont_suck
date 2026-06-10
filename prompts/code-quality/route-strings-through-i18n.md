---
title: Route Strings Through i18n
slug: route-strings-through-i18n
category: code-quality
tags: [universal, i18n, frontend]
works_with: all
severity: medium
one_liner: "AI hardcoding user-facing strings in codebases with a translation layer"
---

# Route Strings Through i18n

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from hardcoding user-facing text in projects where every string goes through a translation system.

**[Copy-paste ready version](../../install/route-strings-through-i18n.md)** — just the instruction block, no explanation.

## The Problem

The codebase wraps every user-visible string in `t('checkout.confirm_button')`, maintains locale files in five languages, and has a process where translators receive new keys each sprint. The AI adds a feature and writes `<button>Confirm order</button>` — raw English, hardcoded, the way ten million training-data tutorials write buttons. The component renders perfectly in the developer's locale, which is English, which is why nobody notices.

Spanish users notice. The new feature is an island of English in an otherwise localized product — and depending on the market, that's somewhere between embarrassing and a regulatory problem. Worse, hardcoded strings are invisible to the translation pipeline: the extraction tooling scans for `t()` calls, finds none in the new code, sends nothing to translators, and the gap persists until a user screenshots it. Every hardcoded string is also a small vote against the system itself; i18n layers survive only under a strings-have-one-path discipline, and each exception makes the next one look normal. The same applies to the adjacent sins: concatenating translated fragments (`t('hello') + ', ' + name`), hardcoding date/number formats, and embedding English into error messages the UI displays.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Route Strings Through i18n

In a codebase with an i18n/translation layer, NEVER hardcode user-facing text. Every string a user can see goes through the translation system — buttons, labels, headings, placeholders, tooltips, error and success messages, empty states, `aria-label`s, email subjects and bodies, validation messages.

A hardcoded string renders fine in your locale and is invisible to the translation pipeline — translators never receive it, and the gap ships to every other language.

**Rules:**
- Detect the layer first: look for `t()`/`$t`/`gettext`/`formatMessage`/`useTranslation`, locale directories (`locales/`, `lang/`, `messages/`), and how the nearest existing component gets its text — then use exactly that mechanism
- New text means a new key: follow the project's key naming scheme (namespacing, casing) and add the entry to the source-language locale file, the same way existing keys are registered. If the project has extraction tooling, write strings the way the extractor can find them (static keys, not dynamically built ones, unless the project does that)
- Never assemble sentences by concatenating translated fragments or interleaving raw text with `t()` calls — word order differs across languages; use the i18n system's interpolation and pluralization (`t('cart.items', { count })`)
- Dates, numbers, and currency follow the same rule: use the project's locale-aware formatters, not hand-rolled `toFixed` and string templates
- Out of scope: log messages, internal errors, code comments, and developer-facing CLI output — unless this project translates those too (check)
- If you can't determine the right key structure or the locale-file workflow, ask — a wrongly registered key still beats a hardcoded string, but the right key beats both

**Red flags that you're about to violate this:**
- "I'll put the English text in for now..."
- "This one label is too small to need translation..."
- "The string is dynamic, so I'll build it with concatenation..."
- "Translation can happen in a later pass..." (the pipeline can't see this string)
- "Error messages don't need i18n..." (users read them)
- Typing user-visible words directly into markup in a repo full of `t()` calls

---

## Why It Works

1. **It names the invisible-to-the-pipeline mechanism.** The AI assumes hardcoded text is a cosmetic shortcut someone will catch. Explaining that extraction tooling literally cannot see untagged strings establishes that *nobody* downstream will catch it — verification has to happen at write time.

2. **It enumerates the forgotten string classes.** Models that do use `t()` for headlines still hardcode aria-labels, placeholders, and validation messages — text that doesn't feel like "content." The explicit list extends the rule to where the misses actually cluster.

3. **It bans concatenation by explaining word order.** Fragment assembly looks i18n-compliant (every piece is translated!) and breaks in any language with different syntax. Giving the reason makes the prohibition stick instead of reading as pedantry.

4. **It bounds the rule to user-facing text.** Demanding translated log lines would make the rule absurd in most projects, and absurd-once means discounted-everywhere. The explicit scope keeps it credible.

## Origin

A localized e-commerce product — six languages, professional translation workflow — shipped a returns flow where every label, error, and confirmation was AI-written hardcoded English. Extraction tooling reported nothing missing, because to the tooling nothing was. The team learned about it from a one-star app review in German, which the translator they then sent the strings to described as "the most fluent German in the whole ticket."
