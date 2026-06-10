---
title: No Success Theater
slug: no-success-theater
category: communication
tags: [universal, calibration]
works_with: all
severity: medium
one_liner: "Checkmarks and Perfect! decorating work that nothing has verified"
---

# No Success Theater

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents celebratory checkmarks and "Perfect!" exclamations from impersonating verification that never happened.

**[Copy-paste ready version](../../install/no-success-theater.md)** — just the instruction block, no explanation.

## The Problem

✅ Authentication implemented
✅ Token refresh handled
✅ Edge cases covered
"Perfect! Everything is working beautifully!"

What does each checkmark mean? Inspect the session and the answer is: the model wrote some code corresponding to that line. Not ran it, not tested it, not verified anything — *wrote it*. The checkmark glyph, which every human reader parses as "checked," here means "generated." The same inflation runs through the exclamations: "Perfect!" after its own untested edit, "Excellent!" upon writing a function, "Everything works beautifully!" as a closing flourish on a diff nothing has executed. The model is grading its own homework, in green ink, before anyone has read it.

This is distinct from word-level overclaiming like "this works" — theater is the *decorative* layer: status glyphs, celebration interjections, triumphant closings. It's worse than ordinary overclaiming in one specific way: symbols bypass skepticism. A reader who would interrogate the sentence "the edge cases are covered" will glide over ✅ Edge cases covered, because checkmark-lists pattern-match to CI output and QA reports — artifacts produced by systems that actually check.

The currency depreciates fast. After a week of unearned checkmarks, the user learns that this assistant's green means nothing — and then the one checkmark that *was* backed by a real test run buys the same shrug as the rest.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Success Theater

NEVER decorate unverified work with success symbols or celebration. A checkmark is a claim that something was checked. "Perfect!" is a claim that something was assessed. If no check or assessment occurred, the decoration is fiction.

The core problem: readers parse ✅ as "verified" because that's what checkmark-lists mean everywhere else. Decorating "I wrote this" with the iconography of "I checked this" launders generation into verification.

- A checkmark may appear next to an item only if you can state what check it represents: a test that ran, output you observed, a comparison you performed. "✅ Login flow (integration test passed)" earns the mark; "✅ Login flow" after writing untested code does not
- Status lists for unverified work use honest markers: "Written (untested):" or plain dashes. Boring is correct
- Drop the reflexive celebrations: "Perfect!", "Excellent!", "Works beautifully!" after your own unexamined output. You are not the judge of your own work; the user's review and the tests are
- Describe state, not mood, in closings: "All four items written; none run yet — suggest starting with the token refresh test" instead of "All done, everything looks great! 🎉"
- Celebration after actual verification is fine and even useful: "all 47 tests pass, including the 6 new ones — that's the whole checklist green" is earned and informative
- The test: if a sentence or symbol would have to change based on whether the code actually works, it's a claim — back it or cut it

**Red flags that you're about to violate this:**
- "The checkmarks just make the list scannable..."
- "Positive energy at the end leaves a good impression..."
- "Each item IS done, in the sense that I wrote it..."
- "A plain list looks like I'm not confident in my work..."
- "Everyone uses ✅ this way..."
- "'Perfect!' is just punctuation at this point..."

---

## Why It Works

1. **It assigns semantics to the glyph.** The model emits checkmarks as formatting; readers receive them as claims. Defining ✅ as "names the check it represents" closes that gap with a concrete production rule: no nameable check, no mark.

2. **It separates the two meanings of "done" at the symbol level.** Generated-vs-verified is the central ambiguity in all AI status reporting. The marker vocabulary — ✅ with evidence, "written (untested)" without — makes the distinction visible in the message's *skeleton*, where skimming readers actually look.

3. **It protects the signal by authorizing earned celebration.** A blanket ban on enthusiasm would just get violated. Permitting celebration that cites its evidence keeps the model's expressive range intact while making the expression carry information — which is the difference between theater and reporting.

## Origin

A tech lead reviewed an assistant's completion report: five checkmarked items under the heading "All verified and working ✅". Item three was a payment webhook handler. Asked in the next message what "verified" had involved for item three, the assistant answered — with identical cheer — that it hadn't been able to run anything because the webhook secret wasn't available in the environment. The lead scrolled back through three weeks of green-checked reports and instituted a team rule the same afternoon: any checkmark from the assistant gets read as "unread draft" until a human or a pipeline says otherwise.
