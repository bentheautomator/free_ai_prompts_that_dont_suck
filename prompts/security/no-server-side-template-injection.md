---
title: Never Render User Input as a Template
slug: no-server-side-template-injection
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI passing user strings into render_template_string or dynamic templates"
---

# Never Render User Input as a Template

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from compiling user-controlled strings as server-side templates, which is code execution.

**[Copy-paste ready version](../../install/no-server-side-template-injection.md)** — just the instruction block, no explanation.

## The Problem

There's a category difference the AI routinely misses: passing user data *to* a template (fine, escaped, normal) versus passing user data *as* the template (code execution). It writes `render_template_string(f"<h1>Hello {name}!</h1>")` in Flask, or feeds a user-edited email template into Jinja2, ERB, or Handlebars compilation, or builds a template string by concatenation before rendering. The user's input is now evaluated in a language with expressions, and `{{ 7*7 }}` coming back as `49` is the doorbell. Jinja2 payloads escalate from there to `__subclasses__` chains and `os.popen`; ERB gets there even faster because it's just Ruby.

The trigger scenarios are predictable: personalized emails and notifications ("let admins customize the message"), CMS-ish features ("users can edit their page template"), and the lazy f-string-into-`render_template_string` shortcut where the AI pre-interpolates user data into the template source before rendering it. That last one looks identical to safe code at a glance, which is why it survives review.

The fix is structural: template source is developer-authored code that lives in files; user input only ever enters through the context dictionary. When users genuinely must author templates, that requires a sandboxed or logic-less engine chosen for the purpose, not the application's full-power one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Render User Input as a Template

NEVER compile or render a string containing user input as a server-side template. User data goes into the template context as a variable; it never becomes part of the template source.

Template engines evaluate expressions. Rendering user input as a template hands users an expression evaluator, which in Jinja2, ERB, Freemarker, and friends escalates to remote code execution.

- Never do: `render_template_string(f"...{user_value}...")`, `Template(user_string).render()`, `ERB.new(params[...])`, `Handlebars.compile(userTemplate)`, or string-concatenating anything user-derived into template source before compilation.
- Always do: `render_template("greeting.html", name=name)` / `res.render("greeting", {name})`, with the template source fixed in a file and the user value passed as context, where the engine escapes it.
- The pre-interpolation variant is the sneaky one: an f-string or `+` that mixes user data into the template string *before* the render call is already the vulnerability, even though the render call itself looks clean.
- For user-customizable content (email templates, notification formats), do not expose the application's template engine. Use a logic-less or sandboxed option: a strict allowlist of `{placeholder}` tokens you substitute yourself with `str.replace`-style logic, Mustache in logic-less mode, or Jinja2's `SandboxedEnvironment` if expressions are truly required (and treat even that as a risk to flag).
- Format strings count: `user_string.format(**data)` on a user-controlled format string leaks object internals via `{0.__class__...}`. Same rule, smaller blast radius.
- If you see `{{7*7}}` rendering as `49` anywhere user input flows, that is an active RCE vector; flag it immediately.

**Red flags that you're about to violate this:**
- "render_template_string saves creating a file for one line of HTML..."
- "Admins write these templates, and admins are trusted..."
- "I'll interpolate the name first, then render the result..."
- "It's just an email template, there's no dangerous data nearby..."
- "The engine escapes variables, so this is safe by default..."
- "Users only have access to a few placeholder variables anyway..."

---

## Why It Works

1. **It names the data/code distinction the AI is blurring.** "Into the context, never into the source" is a one-sentence rule that resolves every variant, including ones not listed.

2. **It spotlights the pre-interpolation trick.** The f-string-then-render pattern is the version AIs actually write, and it defeats rules that only mention "don't render user templates" because the render call looks innocent.

3. **It answers the legitimate requirement.** Customizable emails are a real feature; pointing to placeholder substitution and sandboxed engines means the AI can satisfy the request without the full-power engine.

4. **It gives a detection signature.** The `{{7*7}}` test turns an abstract vulnerability into something the AI can recognize and report when auditing existing code.

## Origin

A marketing feature let staff customize onboarding emails, and the assistant implemented it by storing the template text and passing it straight to the production Jinja2 environment with full context. A compromised staff account later saved a "template" that walked Python's object graph to a subprocess call, running commands on the email worker. The rebuilt feature supported exactly nine `{placeholder}` tokens substituted with plain string replacement, which covered every template staff had ever actually written.
