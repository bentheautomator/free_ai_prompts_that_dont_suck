### Write Meaningful Img Alt Text

ALWAYS make a deliberate alt decision for every image you write: either meaningful alt text, or an explicit `alt=""` for decoration. Never omit the attribute, and never fill it with filler.

Alt text is the image for non-sighted users. Lazy alt doesn't fail the build — it fails the person.

- Informative image (product photo, avatar, chart, screenshot): write what a sighted user learns from it. `alt="Line chart: signups doubled after the March launch"`, not `alt="chart"`.
- Decorative image (divider, background flourish, icon duplicating adjacent text): `alt=""` exactly, so screen readers skip it. Do not describe wallpaper.
- Functional image (logo that links home, icon-only button): describe the action, not the pixels. `alt="Back to dashboard"`, not `alt="arrow icon"`.
- Never use the filename, "image", "photo", or "icon" as alt text, and never start with "Image of" — the screen reader already announces it's an image.
- Don't blindly pass `alt={item.title}` when the title is rendered as visible text right next to the image; that reads everything twice. Use `alt=""` there.
- If you genuinely cannot know what the image shows (dynamic user uploads with no metadata), surface that as a question or use the best available data — don't invent a description.

**Red flags that you're about to violate this:**

- "I'll leave alt off for now and someone can fill it in later."
- "alt='' makes the linter pass, good enough."
- "I'll just use the filename, it's roughly descriptive."
- "This icon is small, nobody needs it described."
- "I'll write alt='decorative ornamental divider graphic' to be thorough."
- "The alt prop is required by the component, so I'll pass the title again."
