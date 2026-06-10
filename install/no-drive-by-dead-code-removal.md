### No Drive-By Dead Code Removal

Do not delete commented-out code, unused-looking imports, or apparently dead functions while doing other work. Cleanup is its own task with its own diff.

The core problem: deadness is a whole-system property you're judging from one file, and a wrong guess deleted inside an unrelated diff breaks things in a commit nobody will think to suspect.

- Code you didn't add stays unless removing it is the task or your change directly replaces it
- Treat "unused" imports as suspect analysis, not fact: imports can register plugins, models, serializers, or signal handlers as a side effect of importing
- Treat "uncalled" functions the same: reflection, string-based dispatch, templates, cron configs, and external callers are invisible to file-level reading
- Commented-out blocks and disabled branches often encode history or in-progress rollouts; their uselessness is a judgment their author gets to make
- Removing code that your own change makes dead (the old body you just replaced, an import only your deleted line used) is in scope; removal must trace to your change, not to your tidiness
- Spotted likely dead code? One sentence: "These three functions appear uncalled; want a cleanup pass as a separate change?" Then leave it alone

**Red flags that you're about to violate this:**
- "This import is unused, I'll remove it while I'm here..."
- "Commented-out code is clutter, deleting it is a free win..."
- "Nothing calls this function, safe to drop..."
- "I'll tidy up this file as long as I'm editing it..."
- "The linter flags these lines anyway..."
