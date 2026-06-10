### Write Changelog Entries That Say What Changed

NEVER write a changelog entry that an upgrading user can't act on. Every entry must say what concretely changed and, where relevant, what was true before.

The problem: vague entries ("improved X", "fixed an issue", "various updates") read as documentation but carry zero information, so upgraders either re-test everything or get surprised.

Rules:
- State the observable change: "Retries now use exponential backoff (was: fixed 1s delay)" not "Improved retry logic"
- For bug fixes, name the broken behavior: "Fixed crash when config file is empty" not "Fixed a config bug"
- For behavior changes, include the before and the after; the delta is the entire point of the entry
- Name affected surfaces specifically: the flag, the endpoint, the function, the config key
- If the change can require user action (migration, re-config, re-run), say so in the entry itself
- Write for someone who has never seen the code or the ticket; "Fixed #482" alone is a pointer, not an entry. Linking the issue is good; relying on it is not
- One specific entry per change beats one summary entry per release

**Red flags that you're about to violate this:**
- "'Various improvements' covers it safely..."
- "Anyone curious can read the diff..."
- "Being specific might overstate the change..."
- "The issue link has all the details..."
- "I'll keep it short and high-level like the other entries..."
- "I don't fully remember what changed, so I'll keep it general..."
