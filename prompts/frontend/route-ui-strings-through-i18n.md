---
title: Route UI Strings Through i18n
slug: route-ui-strings-through-i18n
category: frontend
tags: [universal, frontend]
works_with: all
severity: high
one_liner: "Stops hardcoded English strings in codebases that have an i18n system"
---

# Route UI Strings Through i18n

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from hardcoding user-facing English text in apps that already have a translation system, shipping mixed-language UI to every non-English user.

**[Copy-paste ready version](../../install/route-ui-strings-through-i18n.md)** — just the instruction block, no explanation.

## The Problem

The codebase has `react-i18next`, a `locales/` directory, and ten thousand existing `t('checkout.confirm')` calls. The AI adds a feature and writes `<button>Save changes</button>`. It writes `throw new Error('Please select at least one item')` and renders the message in a toast. It writes `placeholder="Search projects..."`. Each string works perfectly — in English. Every German, Japanese, and Brazilian user now gets a UI that's 97% their language and 3% English, concentrated in exactly the newest features, and the localization team finds out when a customer screenshots it.

Worse are the strings the AI builds by concatenation: `` `${count} items selected` `` or `'Delete ' + name + '?'`. Even once extracted, these can't be translated correctly — languages disagree on word order and plural rules — so the late fix costs more than the early one would have.

Assistants hardcode because the literal string is the zero-friction path: no key to invent, no locale file to touch, and the rendered output looks identical to the correct version in the AI's English-default evaluation. The i18n system is infrastructure the task never mentions, so the AI never looks for it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Route UI Strings Through i18n

If the project has an i18n system, NEVER hardcode a user-facing string. Every piece of text a user can see goes through the translation function — including the ones that don't feel like "content."

One hardcoded string ships English to every locale. The newest features become the most broken ones for international users.

- Before writing any UI text, check how neighboring components produce theirs. If you see `t(...)`, `<FormattedMessage>`, `$t`, or a locales directory, that's the only sanctioned path for strings.
- "User-facing" includes the easy-to-miss surfaces: placeholder text, `aria-label` and `title` attributes, validation and error messages, toast/notification text, empty states, confirm dialogs, button labels, `<option>` labels, and document `<title>`.
- Add the new key to the source-language locale file in the same change, following the project's key naming convention. A `t('untranslated.key')` rendering its raw key is just a different bug.
- Never build sentences by concatenation or naive templates (`'Delete ' + name + '?'`, `` `${n} files` ``). Use the library's interpolation (`t('confirmDelete', { name })`) and plural support (`t('fileCount', { count })`) — word order and plural rules differ across languages, so the string must stay whole inside the translation.
- Don't translate non-UI strings: log messages, error codes, analytics events, and test fixtures stay literal.
- If you cannot find the i18n setup but the repo clearly has locale files, ask rather than hardcoding "temporarily." Temporary English is permanent English.

**Red flags that you're about to violate this:**

- "It's just a button label, I'll inline it."
- "I'll hardcode for now and someone can extract strings later."
- "Placeholders and aria-labels aren't really content."
- "Template literals handle the variable, no need for i18n interpolation."
- "Adding a locale key for one string is overkill."
- "The error message comes from a throw, so it's not UI text."

---

## Why It Works

1. **It makes the check environmental, not task-dependent.** The task prompt never says "this app is localized"; instructing the AI to read neighboring components for `t(...)` surfaces the requirement from the code itself.
2. **It enumerates the invisible string surfaces.** Buttons get extracted while placeholders, aria-labels, and toasts get missed — because they don't pattern-match to "content." The explicit list closes that gap.
3. **It bans concatenation with the linguistic reason attached.** "Use interpolation" alone reads as style; "word order differs across languages" explains why the concatenated version is unfixable later, which sticks.
4. **It kills the deferral.** "Extract later" is the standard rationalization, and the rule's "temporary English is permanent English" names exactly how that plays out.

## Origin

An assistant added a bulk-actions toolbar to a fully localized admin app: five buttons, two confirm dialogs, one toast — all hardcoded English, with `` `${count} rows selected` `` for the counter. It cleared review because every reviewer ran the app in English. The first sign was a support ticket from a French enterprise customer titled "interface partiellement en anglais," and the cleanup meant retrofitting plural-aware keys across nine strings and re-requesting translations for six languages, a two-week round trip for what would have been ten minutes at write time.
