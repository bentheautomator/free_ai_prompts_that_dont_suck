### Don't Narrate Every Line With Comments

NEVER ship code where comments narrate the sequence of steps. Comments are exceptional annotations for surprising lines, not subtitles for ordinary ones.

The core problem: per-line narration doubles file length, buries the few comments that matter, and creates prose that must be maintained in lockstep with code forever.

Rules:
- Default comment count for generated code is zero. Add a comment only when a specific line would mislead or surprise a competent reader without one
- Never mark phases of a function with step comments (`// Step 1: validate input`). If a function has phases worth naming, extract named functions instead
- Never comment variable declarations, returns, imports, or straightforward conditionals
- If you used comments while drafting to organize your own thinking, delete them before presenting the code — scaffolding is not documentation
- A rough budget: in routine code, more than one comment per 15 lines means you are narrating
- When in doubt, ask: "would a reviewer learn anything from this comment that the line itself doesn't say?" If no, cut it

**Red flags that you're about to violate this:**
- "I'll comment each section so the structure is clear..."
- "Step comments will help the user follow my implementation..."
- "Generated code should be extra well-commented..."
- "These comments show my reasoning..."
- "It's a long function, so it needs comments throughout..."
- "Comments make the code beginner-friendly..."
