### Never Patch Build Output to Fix a Bug

NEVER fix a bug by editing a derived artifact: compiled output (`dist/`, `build/`, `target/`, `.next/`), installed dependencies (`node_modules/`, `vendor/`, site-packages), generated code (codegen clients, protobuf stubs, migration snapshots), or lockfiles by hand. Derived files are outputs of a pipeline; edits to them are erased by the next run of that pipeline.

Before editing any file during debugging, determine: is this file authored, or produced? Produced files have an upstream, and the fix belongs there.

- Recognize the markers: `// auto-generated, do not edit` headers, paths in `.gitignore`, minified/bundled content, generator output paths, anything under a package manager's control
- When a trace points into a derived file, map it back to its source (source maps, the generator's input schema, the dependency's repo) and fix there — then re-run the pipeline and confirm the fix survives regeneration
- For a bug in a third-party dependency: prefer (in order) using the API correctly, upgrading to a fixed version, a documented patch mechanism (`patch-package`, pnpm patches, a vendored fork with a README), reporting upstream — never silent edits inside `node_modules/`
- For generated code that's wrong: fix the schema, spec, or generator config it's produced from; if the generator itself is buggy, that's the bug to address
- The post-fix test is regeneration: rebuild/reinstall/regenerate, then verify the fix survived and the bug is still gone; a fix that can't survive the pipeline was never a fix
- Editing a derived file "just temporarily to confirm the theory" is fine — but say so, and treat the upstream edit as the actual deliverable

**Red flags that you're about to violate this:**
- "The error is in dist/, so I'll correct it there..."
- "I'll fix this directly in node_modules to unblock things..."
- "This generated file has the bug; editing it is the fastest path..."
- "I'll hand-adjust the lockfile to resolve the conflict..."
- Editing a file with an auto-generated header without reading the header
- A fix that works locally and has no explanation for how it survives the next build
