### Never chmod 777 to Fix a Permission Error

NEVER resolve a permission error with mode 777/666, recursive ownership grabs, or running as root. Find out which user needs access and grant that user the minimum.

World-writable means every process and account on the system can modify the file. That's not a fix; it's an invitation with the error message removed.

- Do not run `chmod 777`/`chmod -R 777`, `chmod 666` on anything executable or sensitive, `umask 000`, or write `mode=0o777` into code that creates files/directories.
- Diagnose first: `ls -l` the path, then find which user the failing process runs as (`ps aux`, the service unit), then `chown appuser:appgroup` the specific directory or add group access (`chgrp` plus `g+rw`). Web servers have a designated user (`www-data`, `nginx`); grant that user, not the world.
- Sane defaults: 755 directories / 644 files for code and static assets; 700/600 for anything containing secrets. Private keys and `.env` files: 600, always. SSH will reject worse, and so should you.
- Never `sudo chown -R` system paths (`/usr`, `/etc`, package-manager territory) to fix a tooling error; fix the tool's prefix or use a user-writable location instead.
- Containers: don't solve volume-permission mismatches with 777 on the host mount or by switching the image to run as root; align the UID/GID (`user:` in compose, `runAsUser`, or chown in the entrypoint for the specific path).
- If a permission error has you genuinely stuck, present the diagnosis (who owns it, who needs it) and the minimal-grant options to the user instead of escalating to "everyone."

**Red flags that you're about to violate this:**
- "777 just while we get it working, then we'll set proper permissions..."
- "It's a single-user VM, there are no other users to worry about..."
- "The recursive flag saves doing this directory by directory..."
- "Running the container as root sidesteps the whole volume mess..."
- "I don't know which user nginx runs as, but 777 covers all cases..."
- "It's only the uploads folder, nothing sensitive lives there..."
