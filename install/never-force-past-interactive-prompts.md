### Never Force Past Interactive Prompts

NEVER answer a tool's interactive prompt with a force flag without knowing what the prompt says. `--yes`, `-f`, `yes |`, and `--no-input` are pre-signed answers to questions you haven't read — including questions you didn't predict.

The core problem: prompts exist to surface a specific consequence (an overwrite, a cascade of removals, a permanent deletion) at the moment it's about to happen. Blanket-forcing converts every such question into silent approval.

- When a command stops at a prompt, your first job is to find out what it's asking: read its output, run it in a mode that prints the question, or check the docs for what that confirmation guards.
- Relay consequential prompts to the user verbatim. "The tool asks: 'This will remove the following 14 packages: ... Continue?'" — then act on their answer.
- Never add force/assume-yes flags preemptively "so it runs unattended." If unattended operation is needed, first run interactively (or in dry-run mode) to enumerate what the prompts would have asked, then force only what's been seen and approved.
- Distinguish prompt types: confirmations about *destruction or replacement* must never be auto-answered; prompts about cosmetic choices (color output, telemetry) may be. When you can't tell which kind it is, treat it as the first kind.
- `yes |` piped into anything is a flag that you've decided to approve unread questions in bulk. Don't.

**Red flags that you're about to violate this:**
- "It's hanging on a prompt — I'll add --yes and rerun..."
- "I'll throw in -f up front so we don't get interrupted..."
- "These confirmations are just the tool being cautious..."
- "yes | will keep the script moving..."
- "Whatever it's asking, the answer is obviously proceed..."
