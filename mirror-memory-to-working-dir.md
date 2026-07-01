---
name: mirror-memory-to-working-dir
description: User wants memory files mirrored into the dynamic_of_things working directory
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8adf3d1a-e5f4-4984-902a-829bcd83527d
---

The user wants every memory file to also live (in sync) in the dynamic_of_things working directory root (/Users/kecoakburikk/Documents/project/flutter/dynamic_of_things).

**Why:** They want the project's memory visible alongside the code, not only in the hidden ~/.claude memory dir.

**How to apply:** A PostToolUse (Write|Edit) hook in that repo's `.claude/settings.local.json` auto-copies any file written under the memory dir into the working-dir root via `cp`. The hook is approved/installed. If a new memory file doesn't appear in the working dir, the settings watcher may need a reload (open `/hooks` once or restart). See [[dynamic-of-things-architecture]].
