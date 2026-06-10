---
title: Never Inject User Data Into HTML Unescaped
slug: no-unsanitized-html-injection
category: security
tags: [universal, security, xss]
works_with: all
severity: critical
one_liner: "AI using innerHTML and dangerouslySetInnerHTML with user content"
---

# Never Inject User Data Into HTML Unescaped

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing cross-site scripting bugs via innerHTML, v-html, and template escapes.

**[Copy-paste ready version](../../install/no-unsanitized-html-injection.md)** — just the instruction block, no explanation.

## The Problem

User content needs to appear on a page, and the AI takes the path that renders fastest: `el.innerHTML = comment.text`, `dangerouslySetInnerHTML={{__html: bio}}`, `v-html="description"`, or `{!! $content !!}` in Blade, `| safe` in Jinja, `<%- %>` in EJS. Each of these is a deliberate escape hatch out of the framework's XSS protection, and the AI pulls the lever casually, usually because the content contains line breaks or bold tags and `textContent` "loses the formatting." One stored `<img src=x onerror=...>` later, every viewer of that comment runs attacker JavaScript with their session.

The pattern shows up most when rendering rich-ish text (comments, bios, descriptions), when concatenating HTML strings server-side (`html += "<li>" + name + "</li>"`), and when the AI builds DOM from template literals. It also shows up as cargo-culted `dangerouslySetInnerHTML` copied from a markdown-rendering example, minus the sanitizer the example had. Stored XSS is the worst variant: the payload sits in your database and fires on every render, including in admin panels where the victim's session can do real damage.

Frameworks escape by default precisely so this requires opting out. The instruction's job is to make opting out expensive.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Inject User Data Into HTML Unescaped

NEVER render user-controlled content through an HTML-injection sink without sanitization. Default to text rendering; treat every escape hatch as requiring justification.

Frameworks escape output by default. `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `| safe`, `{!! !!}`, and `<%- %>` are opt-outs, and opting out with user data is stored XSS.

- Rendering text: use `textContent`, JSX `{value}`, `{{ value }}` (auto-escaping templates). Never switch to an HTML sink just to get line breaks; use CSS `white-space: pre-wrap` or split into elements.
- Rendering rich text/markdown from users: sanitize the produced HTML with DOMPurify (or bleach in Python, sanitize-html in Node) immediately before the sink. Markdown renderers do not sanitize by default; `marked(userText)` into `innerHTML` is XSS.
- Building HTML server-side by string concatenation with user values is the same bug; use the template engine's escaping, never manual `replace('<', '&lt;')` half-measures.
- URLs are a sink too: validate that user-supplied `href`/`src` values have `http:`/`https:` schemes; `javascript:alert(1)` survives HTML escaping.
- Do not write your own sanitizer or regex-strip `<script>` tags; bypasses are a hobby industry. Use the maintained library.
- "From our database" is not "safe": if a user ever wrote it, it's user content, including names, filenames, and webhook payloads from third parties.
- When you must use a dangerous sink legitimately (sanitized markdown, trusted CMS content), add a comment stating the data source and why it's safe.

**Red flags that you're about to violate this:**
- "textContent strips the formatting, innerHTML preserves it..."
- "This field is just a display name, nobody puts HTML in a name..."
- "The value comes from our own API, it's already clean..."
- "I'll strip script tags with a regex before inserting..."
- "It's an admin-only page, admins won't attack themselves..."
- "The markdown library probably escapes things..."

---

## Why It Works

1. **It inverts the default at the sink.** The AI chooses `innerHTML` for convenience, not malice. Framing every HTML sink as an opt-out needing justification makes the safe sink the path of least resistance.

2. **It targets the markdown trap specifically.** Markdown-to-HTML into `innerHTML` is the single most common AI-generated XSS, and the fact that renderers don't sanitize is exactly the assumption the AI gets wrong.

3. **It covers the `javascript:` URL gap.** Escaping-focused rules miss attribute-context attacks entirely; adding scheme validation closes the hole that survives perfect HTML encoding.

4. **It pre-rejects the regex sanitizer.** Left to itself, an AI "fixes" XSS by stripping `<script>`, which fails against event handlers and SVG. Mandating the maintained library prevents the confident wrong fix.

## Origin

A feedback widget displayed customer comments to support staff, and the assistant used `dangerouslySetInnerHTML` so emoji and line breaks would "render properly." A customer submitted a comment containing an `onerror` payload that ran in the support dashboard, lifted the agent's session cookie, and pivoted into the admin tools. The patched version was `white-space: pre-wrap` and plain JSX text, which also rendered the emoji fine, because emoji are just text.
