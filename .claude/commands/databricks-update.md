---
description: Update the Databricks MCP Toolkit to the latest version
allowed-tools: Bash
---

Update the Databricks MCP Toolkit by running the update script:

```bash
~/.local/share/databricks-mcp/update.sh
```

After execution:
1. Show the script output to the user
2. Inform them that a restart of Claude Code is required to apply the changes (exit with `exit` and reopen with `claude`)

If the update fails or encounters permission issues, instruct the user to run the command manually in their terminal:

```
~/.local/share/databricks-mcp/update.sh
```

Tell them to copy and paste this command directly into their terminal (outside of Claude Code).
