---
title: Stub External Side Effects in Dev Scripts
slug: stub-external-side-effects-in-dev
category: code-safety
tags: [universal, api, automation]
works_with: all
severity: critical
one_liner: "AI sending real emails, webhooks, or charges while testing a script"
---

# Stub External Side Effects in Dev Scripts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from making real external things happen — emails, SMS, charges, webhooks — while "just testing" code.

**[Copy-paste ready version](../../install/stub-external-side-effects-in-dev.md)** — just the instruction block, no explanation.

## The Problem

The AI writes a script that processes a user list and emails each one. To verify it works, it runs the script. The script works. Four hundred customers receive a half-finished email with `{first_name}` unrendered in the greeting, because "run it and see" was the AI's idea of a test and the SMTP credentials in the environment were real.

Code that calls external services is a loaded gun, and AI assistants test it by pulling the trigger. Emails, SMS, push notifications, payment charges, webhook deliveries, calendar invites, support tickets — these don't have an undo. You can't unsend an email or unring a customer's phone. The AI defaults to live execution because the script's success criterion is "did it run without errors," and the most direct way to check is to run it. Whether the side effects were real never enters the evaluation.

The deeper trap: dev environments often carry live credentials, because someone needed them once. The AI assumes "I'm in a dev environment" implies "nothing here is real." Those are unrelated facts.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stub External Side Effects in Dev Scripts

NEVER execute code that sends, charges, notifies, or posts to external services as a way of testing it. Real emails, SMS, charges, and webhooks have no undo.

The core problem: "run it and see if it works" is live-firing the side effects. Being in a dev environment does not mean the credentials in it are fake — dev environments accumulate live keys.

- Before running anything that touches an external service, identify every outbound side effect: email, SMS, push, payments, webhooks, third-party API writes, ticket/issue creation.
- Verify the credentials/mode in use are sandbox or test-mode (test API keys, a mail-catcher like Mailhog/Mailpit, webhook endpoints pointed at request bins). If you can't confirm it's sandboxed, treat it as live.
- Default to stubbing: a `--dry-run` path that logs what *would* be sent, environment-gated no-op senders, or a hardcoded allowlist of internal test recipients.
- Never test recipient loops against real recipient data. One test address, or fabricated data, until the user approves a live run.
- A live run is something the user explicitly authorizes, with stated scope ("send to these 5 internal addresses"), never something you decide.
- Pay special attention to retries and loops — a bug in send-and-retry logic multiplies real-world side effects.

**Red flags that you're about to violate this:**
- "I'll just run it once to make sure it works end to end..."
- "It's the dev environment, the keys are probably test keys..."
- "Only a few records will actually trigger sends..."
- "The fastest way to verify the webhook is to fire it..."
- "I'll use the real customer list but it's basically harmless..."

---

## Why It Works

1. **It severs "dev environment" from "fake credentials."** The AI's central false assumption is that context implies sandbox. Stating they're unrelated facts forces an actual check of which keys are loaded.

2. **It changes the test procedure, not just the caution level.** "Stub, mail-catcher, allowlist, dry-run" gives the AI a concrete alternative to live execution, so "how else would I test it?" stops being a justification.

3. **It moves live-run authority to the user.** Defining a live send as something only the user can authorize, with explicit scope, removes the AI's discretion at the exact moment it's most overconfident.

## Origin

An assistant built a re-engagement email script and ran it to "verify the template rendering." The environment's SMTP credentials were production ones, left over from a deliverability investigation. Several hundred customers received an email with broken merge tags and a subject line that said TEST. Support spent the next morning answering replies. The template, ironically, had a rendering bug the script test didn't catch — it only proved the sending worked.
