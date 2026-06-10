---
title: Verify the Git Host Before Platform Advice
slug: verify-the-git-host-before-platform-advice
category: context
tags: [universal, environment, assumptions]
works_with: all
severity: medium
one_liner: "AI giving GitHub-specific advice to a repo hosted on GitLab or Bitbucket"
---

# Verify the Git Host Before Platform Advice

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from assuming every repo lives on GitHub when the remote says otherwise.

**[Copy-paste ready version](../../install/verify-the-git-host-before-platform-advice.md)** — just the instruction block, no explanation.

## The Problem

"Open a PR and the GitHub Action will run" — said to a team on a self-hosted GitLab, where the unit of review is a merge request and the automation is a pipeline defined in `.gitlab-ci.yml`. GitHub dominates the AI's training data so thoroughly that it becomes the assumed substrate of all collaboration: `gh` CLI commands for repos with no GitHub remote, `.github/workflows/` files created next to an existing `.gitlab-ci.yml`, CODEOWNERS syntax from the wrong platform, branch-protection walkthroughs for an admin UI the user has never seen.

The vocabulary mismatch is the visible symptom — PR vs merge request vs pull request (Bitbucket's flavor) — but the mechanical failures cost more. A `.github/workflows/ci.yml` committed to a GitLab repo is dead YAML that will never execute; the user believes CI exists. `gh` commands error out, or worse, operate on a stale GitHub mirror of a repo whose real home moved years ago. Webhook setup instructions, release automation, review-assignment advice — all platform-specific, all confidently wrong on the wrong host.

The host is one command away: `git remote -v` names it, and the repo's existing CI files confirm it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify the Git Host Before Platform Advice

NEVER assume a repository is hosted on GitHub. Check the remote before giving platform-specific advice, commands, or config — GitHub is your training-data default, while real repos live on GitLab, Bitbucket, Gitea, Azure DevOps, and self-hosted instances of all of them.

Wrong-platform advice ranges from embarrassing (PR vs merge request) to silently broken: a workflow file the host will never execute.

**Before anything platform-specific:**
- Run `git remote -v` and read the host from the URL — including self-hosted domains, which won't say github.com but might still be GitLab or Gitea under the hood
- Cross-check with the repo's existing platform files: `.github/` vs `.gitlab-ci.yml` vs `bitbucket-pipelines.yml` vs `azure-pipelines.yml` — what already exists tells you what executes here
- Use the host's vocabulary and tooling: merge requests and `glab` for GitLab, pull requests and `gh` for GitHub — don't prescribe CLI tools for the wrong platform
- Write CI/automation in the host's format and location; never create `.github/workflows/` in a repo whose remote and existing CI say otherwise
- Platform features differ in shape, not just name: CODEOWNERS syntax, protected-branch semantics, review and approval rules, release mechanisms — verify the feature exists on this host before walking the user through it
- Multiple remotes or a mirror setup? Determine which remote is canonical (where reviews happen) before advising — pushing to the mirror is its own classic mistake

**Red flags that you're about to violate this:**
- "Just open a PR on GitHub..."
- "Add a GitHub Action for that..."
- "Use gh to create the release..."
- "Repos are on GitHub unless someone says otherwise..."
- "The platforms are basically the same, the advice transfers..."
- Writing platform-specific config without having seen the remote URL this session

---

## Why It Works

1. **It names the substrate assumption.** GitHub functions as invisible background in the AI's reasoning, not as a checkable claim; surfacing it as a default-to-verify makes the one-command check happen.

2. **It pairs the remote with the evidence on disk.** Existing CI files show what the host *executes*, which catches self-hosted instances and mirrors that the URL alone can mislead about.

3. **It blocks the dead-YAML failure specifically.** Wrong-platform workflow files are the silent variant — valid, committed, and inert. Tying CI format to verified host prevents fake automation from entering the repo.

4. **It elevates feature-shape differences over naming.** Translating "PR" to "MR" is trivial; assuming GitHub's protection or approval semantics on another host is the substantive error this rule actually catches.

## Origin

An AI set up release automation for a team: a polished GitHub Actions workflow, tag-triggered, with `gh release create` for the artifacts. The repo lived on self-hosted GitLab; the remote URL said so, and a working `.gitlab-ci.yml` sat in the root the whole time. The workflow file merged anyway — reviewers skimmed it as "CI stuff" — and three releases were "automated" before anyone noticed the artifacts were being built by hand by the one engineer who hadn't trusted the new system. The fix was a GitLab pipeline job; the lesson was a `git remote -v` that nobody had run.
