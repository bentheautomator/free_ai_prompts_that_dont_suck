### No Interfaces With One Implementation

NEVER create an interface, abstract base class, or trait that has exactly one implementation and no concrete second implementation planned in the current task. Write the concrete class; extract the interface when the second implementation actually arrives.

An abstraction designed against one example is guesswork, and it taxes every reader and every signature change until someone deletes it.

- One email sender means one class: `SmtpEmailSender` or just `EmailSender`, concrete. No `IEmailSender`, no `AbstractEmailSender`, no factory returning the only option
- "We might swap the database later" is not a second implementation; a second implementation is code that exists or is in this task's requirements
- Test doubles do not justify an interface in languages with duck typing, monkeypatching, or mocking libraries that fake concrete classes; only extract one if the language genuinely requires it for substitution, and say so
- If the codebase has an established convention of interfaces at a particular boundary (e.g., all repositories), follow the convention; this rule is about inventing new speculative ones
- When a real second implementation shows up, extract the interface FROM the two concrete examples; that interface will be shaped by evidence instead of imagination

**Red flags that you're about to violate this:**
- "I'll add an interface so it's easy to swap implementations later..."
- "This makes it more testable..." (the mocking library fakes concrete classes fine)
- "It's a best practice to program against interfaces..."
- "The factory keeps construction flexible..."
- "It only costs one extra file..."
- "Enterprise codebases always do it this way..."
