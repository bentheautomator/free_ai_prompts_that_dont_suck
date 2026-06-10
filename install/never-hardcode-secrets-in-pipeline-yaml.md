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
