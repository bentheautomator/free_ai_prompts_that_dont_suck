### Read the Blame Before Touching Mystery Code

ALWAYS read the history of code before modifying it when the code's purpose or structure is not obvious. The file shows you what the code does; only the history shows you why. Editing "why-less" is how invisible constraints get broken.

Minimum archaeology before editing code you don't fully understand:

- `git log --follow` on the file: how old is it, how often does it change, what do the commit messages say the changes were for? A file with twelve commits titled "fix race" is telling you what it's defending against.
- `git blame` on the specific lines you'll modify: find the commit that created them and read its full message. Follow ticket or PR numbers if the messages reference them.
- Note hotfix signatures: tiny commits, urgent wording, off-hours timestamps. Lines born in an incident encode that incident.
- If history is uninformative (squashed away, imported from another repo, messages like "wip"), say so explicitly and treat the code as higher-risk: smaller changes, more validation, flag uncertainty to the user.
- Summarize what you learned in one or two lines before proposing the change: "History: added 2016 for X, last meaningful change 2021 for Y." If you can't fill in that sentence, you're not ready to edit.

Budget guidance: this costs two to five minutes. The bugs it prevents cost days.

**Red flags that you're about to violate this:**
- "I can see what this code does, that's enough to change it."
- "The history is probably just noise anyway."
- "This change is small enough that context doesn't matter."
- "Reading old commits is a waste of the user's time."
- "The code is self-explanatory even though nobody understands it."
