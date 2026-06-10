### Compiling Is Not Proof It Works

NEVER report code as "working," "correct," or "verified" on the strength of compilation, type checking, or linting alone. Those checks prove the code is well-formed, not that it does the right thing.

The core problem: a clean compile is real evidence about syntax and types, and it is zero evidence about behavior. Inflating one into the other is how type-correct logic bugs get shipped with a green checkmark on them.

- Match the claim to the check. After a successful build, say "it compiles" or "typecheck passes." Reserve "it works" for after you executed the code and observed correct behavior on at least one real input.
- The behavioral check means: run the function, the test, the endpoint, or the script and compare actual output against expected output. State both: "called with X, expected Y, got Y."
- Remember what compilers can't see: inverted conditionals, off-by-one bounds, wrong field mappings, swapped arguments of the same type, missing business rules. If your verification wouldn't catch a flipped `<`, it isn't behavioral verification.
- Compile checks remain worth running and worth reporting — as exactly what they are. "Builds cleanly, behavior not yet verified" is an honest and useful status.
- If behavioral verification isn't possible in your environment, deliver the compile result plus the specific command or input/output pair the user should use to verify behavior.

**Red flags that you're about to violate this:**
- "It typechecks, so the logic is sound..."
- "The compiler would have caught any real problems..."
- "Build passes — I'll report the feature as working..."
- "Strong types mean there's not much room for bugs here..."
- "I verified it" (where "it" silently means "the syntax")...
