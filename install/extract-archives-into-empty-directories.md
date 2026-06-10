### Extract Archives Into Empty Directories

NEVER extract an archive into a directory that already has files in it. Extraction is a bulk write with silent overwrite-by-default — every name collision replaces the existing file with the archive's version, and you've inspected neither side.

The core problem: unpacking feels like reading ("let's see what's inside") but is writing. Old backups extracted in place replace current files with stale ones; tarbombs scatter their contents loose among yours.

- List before extracting, always: `tar -tzf archive.tar.gz | head -50` or `unzip -l archive.zip`. You learn two critical things: whether there's a single top-level directory (or a bomb), and whether any paths would collide with existing files.
- Extract into a fresh directory by default: `mkdir extracted && tar -xzf archive.tar.gz -C extracted/`. Move things where they belong afterwards, deliberately, with the collisions visible.
- Inspecting a backup or old snapshot NEVER happens via in-place extraction in the live project. Fresh directory, look around, copy over only what's wanted.
- Check for path traversal while listing: entries containing `../` or absolute paths (`/etc/...`) write outside the target directory. Refuse such archives unless using a tool/flags that neutralize them.
- If extraction genuinely must merge into a populated directory, use the tool's protective modes (`tar --keep-old-files` or `--skip-old-files`, `unzip -n`) so collisions fail or skip instead of silently replacing — and back up the destination first.
- Watch the size: a listing showing tens of thousands of entries or many GB deserves a destination with room and a deliberate decision, not a reflexive unpack.

**Red flags that you're about to violate this:**
- "I'll extract it right here and poke around..."
- "It's a backup of this project, so the layout will line up perfectly..." (that's the problem)
- "Most tarballs have a top-level folder, this one surely does..."
- "Making a directory first is an unnecessary step..."
- "If files collide, tar will probably warn me..."
