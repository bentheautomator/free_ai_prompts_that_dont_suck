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
