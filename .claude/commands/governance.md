---
description: Audit data governance and access permissions in Unity Catalog
allowed-tools: mcp__databricks__run_sql, mcp__databricks__list_catalogs, mcp__databricks__list_schemas, mcp__databricks__list_tables, mcp__databricks__describe_table, mcp__databricks__get_grants, mcp__databricks__get_effective_grants
---

The user wants to audit data governance and access permissions in their Databricks Unity Catalog environment.

## Instructions

1. **Identify scope**: if the user specifies a catalog, schema, or table, focus on that object. If no scope is given, start with a full catalog inventory using `list_catalogs`.

2. **Audit direct grants**: for each target object, use `get_grants` to list direct permission assignments. Check at catalog, schema, and table levels as appropriate.

3. **Audit effective grants**: use `get_effective_grants` on key objects to understand the full permission picture including inheritance.

4. **Check access patterns** (if system tables are available): query `system.access.audit` for recent access activity:
   ```sql
   SELECT action_name, request_params.full_name_arg, user_identity.email,
          COUNT(*) as access_count
   FROM system.access.audit
   WHERE datediff(current_date(), event_date) <= 30
   GROUP BY 1, 2, 3
   ORDER BY access_count DESC
   LIMIT 50
   ```

5. **Identify governance issues**:
   - Overly permissive grants (ALL PRIVILEGES on broad scopes)
   - Direct grants on tables instead of schema/catalog level
   - Principals with access but no recent activity (potential orphaned grants)
   - Missing ownership assignments

6. **Generate report**: produce a structured governance report with:
   - Inventory summary (catalogs, schemas, tables)
   - Permission matrix (who has access to what)
   - Findings (issues found, severity: high/medium/low)
   - Recommendations (specific actions to remediate each finding)

## User input

$ARGUMENTS
