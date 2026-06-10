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
