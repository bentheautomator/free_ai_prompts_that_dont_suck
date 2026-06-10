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
