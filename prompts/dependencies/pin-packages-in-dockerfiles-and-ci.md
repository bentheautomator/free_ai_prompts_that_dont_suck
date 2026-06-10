---
title: Pin Packages in Dockerfiles and CI
slug: pin-packages-in-dockerfiles-and-ci
category: dependencies
tags: [universal, dependencies, versions]
works_with: all
severity: high
one_liner: "Stops unpinned installs in Dockerfiles and CI that drift under your feet"
---

# Pin Packages in Dockerfiles and CI

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing `RUN pip install foo` and `npm install -g tool` in Dockerfiles and CI configs, where nothing pins them.

**[Copy-paste ready version](../../install/pin-packages-in-dockerfiles-and-ci.md)** — just the instruction block, no explanation.

## The Problem

Lockfiles protect the dependencies in your manifest. They do nothing for the installs an AI assistant scatters through infrastructure files: `RUN pip install awscli` in a Dockerfile, `npm install -g vercel` in a deploy workflow, `uses: some-action@v4` resolving a moving tag, `FROM python:3` floating across minor versions of an entire interpreter. Each of these resolves at build time, against whatever the registry serves that day, on machines that rebuild constantly.

These are the installs that break Friday deploys. The application code is untouched, the lockfile is untouched, and yet the image build fails — because a CLI tool shipped a new major overnight and the Dockerfile said, in effect, "give me whatever's newest." Worse than failing loudly is succeeding differently: a linter that updates mid-week starts flagging new violations on untouched PRs, and the team burns a morning discovering that "CI" changed, not the code.

Assistants write unpinned infrastructure installs because that's how every quickstart writes them. The Dockerfile reference examples, the action READMEs, the tool installation docs — all optimized for "get the newest thing now," none of them responsible for your reproducibility next quarter.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Pin Packages in Dockerfiles and CI

ALWAYS pin an explicit version for every package installed in a Dockerfile, CI workflow, or provisioning script. These installs run outside the lockfile's protection and re-resolve on every build — unpinned, they are a different build every week.

- Dockerfiles: `RUN pip install awscli==1.33.0`, not `RUN pip install awscli`. Base images get specific tags (`FROM python:3.12.4-slim`), never `latest` and never a bare major (`python:3`).
- CI workflows: pin tool installs (`npm install -g vercel@34.2.0`), pin action versions to a tag at minimum, and pin language setup steps to exact versions where the project depends on behavior (`node-version: 20.14.0`).
- Find the current version honestly before pinning: `npm view <pkg> version`, `pip index versions <pkg>`, or the registry page. Never invent a version number from memory — your recall of "current" is stale by definition.
- Linters, formatters, and scanners installed in CI must be pinned exactly. A floating linter version means PR checks change without any commit, which poisons trust in the whole pipeline.
- When you touch an existing Dockerfile or workflow that has unpinned installs, flag them. Don't silently re-pin someone else's lines without being asked, but say what you saw.

**Red flags that you're about to violate this:**
- "The quickstart installs it without a version, so that's the convention."
- "latest is fine for a build tool; it's not shipped to users."
- "Pinning means we'll fall behind on updates."
- "I don't know the current version, so I'll leave it floating."
- "The lockfile handles versioning for this project."

---

## Why It Works

1. **It names the gap in the AI's mental model**: the assumption that the lockfile covers everything. Infrastructure installs are outside it, and the rule says so in the first line.
2. **It forbids inventing version numbers**, closing the failure where the AI pins to a hallucinated version — and gives the lookup commands so honesty is cheap.
3. **It singles out linters and scanners**, the unpinned installs with the highest confusion-per-byte: their drift looks exactly like developer error.
4. **It distinguishes "pin what you write" from "rewrite what exists,"** so the AI doesn't turn a one-line task into a repo-wide re-pinning crusade.

## Origin

A deploy workflow written by an assistant installed a cloud CLI with no version. Months later the CLI shipped a major that renamed a subcommand, and every deploy across every branch failed simultaneously on a Friday afternoon — with zero changes anywhere in the repo. The fix was one `==` and a version number; finding out that was the fix took four engineers comparing a passing Tuesday build log against a failing Friday one, line by line.
