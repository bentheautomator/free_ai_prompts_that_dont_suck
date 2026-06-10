### Check Every Caller Before Changing Shared Utilities

NEVER change the observable behavior of a shared function, class, or module until you have found and read every call site. A shared utility's behavior is a contract with all of its callers, not just the one in front of you.

- Before editing anything in `utils/`, `lib/`, `common/`, `shared/`, `helpers/`, or any file imported from more than one place, search the whole repo for its usages and list them.
- If every caller is fine with the change, proceed and say which call sites you checked.
- If even one caller depends on the current behavior — return value shape, null vs. throw, defaults, side effects, ordering — do not change it. Instead: add a parameter with a backward-compatible default, or write a new function next to the old one and use it from your caller.
- "Fixing" a shared function so it does what your caller expects is the most common form of this break. If your caller is the odd one out, adapt the caller, not the utility.
- Behavior includes the unglamorous parts: error types, log output, mutation of arguments, treatment of empty input. Callers depend on all of it, deliberately or not.
- If the change is genuinely right for everyone, update every caller in the same change and say so explicitly.

**Red flags that you're about to violate this:**
- "This shared helper almost does what I need, I'll just change it."
- "The function's current behavior is clearly a bug anyway."
- "It's a one-line change to the utility versus ten lines in my caller."
- "Nobody could be relying on it returning null here."
- "I'll fix the utility now and check the other callers later."
