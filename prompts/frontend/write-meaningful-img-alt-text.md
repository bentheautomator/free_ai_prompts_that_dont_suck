---
title: Write Meaningful Img Alt Text
slug: write-meaningful-img-alt-text
category: frontend
tags: [universal, frontend, accessibility]
works_with: all
severity: high
one_liner: "Stops missing, lazy, or redundant alt text on images that carry meaning"
---

# Write Meaningful Img Alt Text

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping images with no alt attribute, filename-as-alt, or "image of image" filler that tells screen reader users nothing.

**[Copy-paste ready version](../../install/write-meaningful-img-alt-text.md)** — just the instruction block, no explanation.

## The Problem

When an AI assistant writes an `<img>` tag, the alt attribute gets one of three treatments: omitted entirely, stuffed with garbage (`alt="image"`, `alt="photo1.png"`, `alt={product.name}` on an image that's purely decorative), or — in linted codebases — gamed with `alt=""` on images that actually carry information, because empty alt silences the eslint warning. All three pass visual review, because alt text is invisible by definition.

The failure compounds in the other direction too. Given a decorative divider or a background flourish, the AI writes `alt="decorative wave pattern separator"`, forcing screen reader users to sit through a description of wallpaper. The AI treats alt as a box to fill rather than a decision: does this image convey information a sighted user gets and a non-sighted user would miss? It never asks, because the JSX compiles and the page renders either way.

Missing alt on a product image means a shopper can't tell what they're buying. Missing alt on a chart means the data exists only for sighted users. This is a WCAG 1.1.1 failure and one of the first things any audit flags.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It converts alt from a field into a three-way decision.** The AI's failure is treating alt as syntax to satisfy; informative/decorative/functional gives it a classification step it can actually perform before writing the attribute.
2. **It bans the linter-gaming move by name.** `alt=""` on an informative image is the most common "compliant" violation, and it only happens because empty string silences tooling.
3. **It blocks both failure directions.** Rules that only say "always describe images" cause the decorative-wallpaper-narration problem; this one makes silence the correct answer for decoration.
4. **It removes the deferral loophole.** "Fill it in later" is how `alt=""` placeholders fossilize into production; requiring the decision at write time closes that path.

## Origin

A storefront team had an assistant build their product gallery component. Every image got `alt=""` because the project's a11y lint rule required the attribute and empty string was the fastest way to satisfy it. The store passed CI for months. A screen reader user emailed support asking why every product page contained "forty unlabeled images" — the entire catalog was undifferentiated silence. The fix required threading product metadata through three layers of components that had been built without it.
