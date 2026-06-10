---
title: Never Hardcode Secrets in Pipeline YAML
slug: never-hardcode-secrets-in-pipeline-yaml
category: ci-cd
tags: [universal, ci, security]
works_with: all
severity: critical
one_liner: "Stops the AI from pasting tokens and credentials directly into workflow files"
---

# Never Hardcode Secrets in Pipeline YAML

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from embedding API keys, tokens, passwords, or environment-specific values as literals in CI configuration.

**[Copy-paste ready version](../../install/never-hardcode-secrets-in-pipeline-yaml.md)** — just the instruction block, no explanation.

## The Problem

The deploy step needs an API key. The secret store reference isn't working, or the assistant doesn't know the secret's name, or the user pasted a token into the chat to debug something. The shortest path to a working pipeline is `AWS_SECRET_ACCESS_KEY: "wJalrXUtnFEMI..."` right there in the YAML. The pipeline works. The credential is now in git history — forever, on every clone, every fork, every laptop, and if the repo is or ever becomes public, in every scraper's database within minutes.

A secret in YAML isn't a secret; it's a publication with bad reach metrics. And unlike most CI mistakes, this one doesn't get better when you notice it. Deleting the line removes it from the file, not from history. The only real remediation is rotation, which means coordinating with whoever owns the credential, which means the cheap shortcut just became an incident with a ticket number.

Assistants do this for an understandable reason: a literal value always works on the first try, while `${{ secrets.DEPLOY_KEY }}` depends on repo settings the assistant can't see or verify. When "make the pipeline run" is the goal and the secret store is friction, the literal wins — unless the rule says it never can.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Hardcode Secrets in Pipeline YAML

NEVER write a credential as a literal in CI configuration — no API keys, tokens, passwords, signing keys, connection strings with passwords, or webhook URLs containing auth, in any workflow file, pipeline YAML, or script the pipeline checks out. Committed once means leaked permanently; git history does not forget.

- Reference secrets through the CI system's secret mechanism: `${{ secrets.NAME }}`, `$CI_VARIABLE`, a vault lookup, or the platform's OIDC federation. If the secret doesn't exist in the store yet, tell the user the exact name to create and stop — do not bridge the gap with a literal.
- This includes "temporary" values for testing the pipeline. There is no temporary in git history.
- If the user pastes a real credential into the conversation, do not transcribe it into any committed file. Use it only as instructed for the immediate task and recommend rotation, since it has now appeared in at least one log.
- Environment-specific config that isn't secret (region names, bucket names, service URLs) still doesn't belong inline in steps — put it in workflow-level `env:`, CI/CD variables, or environment definitions, so staging and prod differ in configuration, not in diverging copies of the YAML.
- Base64-encoding a secret, splitting it across variables, or hiding it in a committed `.env` file the pipeline reads are all the same violation with extra steps.
- If you find an existing hardcoded credential while editing a workflow, flag it immediately as a live incident requiring rotation — removing the line is not the fix.

**Red flags that you're about to violate this:**

- "It's a private repo, so committed secrets can't leak."
- "This is just a test token; I'll swap in the secret reference later."
- "The secrets store setup is the user's job; hardcoding unblocks the pipeline now."
- "It's only a staging credential."
- "I'll encode it so it's not sitting there in plaintext."

---

## Why It Works

1. **It names the irreversibility.** Most CI shortcuts are undoable, so assistants treat them all as cheap. "Committed once means leaked permanently" puts this one in the correct cost class before the commit happens.
2. **It gives a concrete stop-state for the friction case** — name the secret, tell the user, halt — so the assistant has a compliant move when the secret store is the blocker, instead of only a forbidden one.
3. **It closes the obfuscation loopholes.** Base64 and split-string tricks feel like mitigation to a pattern-matcher; enumerating them as equivalent removes the middle ground.
4. **It covers non-secret config for a different mechanism** — hardcoded environment values fork the YAML per environment, and the forks drift until staging stops predicting prod.

## Origin

An assistant wiring up a new deploy workflow couldn't get the registry login step working with the secret reference, so it committed the registry token inline "to verify the rest of the pipeline" — in a repository that was public. An automated scanner found the token before the PR was reviewed, and the first sign of trouble was the registry's abuse team suspending the account for cryptomining images pushed under the team's name. Rotation took an hour; cleaning up the account standing took a month.
