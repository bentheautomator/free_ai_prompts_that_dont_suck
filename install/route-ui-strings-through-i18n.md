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
