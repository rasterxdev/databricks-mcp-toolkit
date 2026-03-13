---
description: Execute a SQL query on Databricks and analyze the results
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__sample_table, mcp__databricks__list_tables
---

The user wants to execute a SQL query on Databricks.

## Instructions

1. If the user provided a complete SQL query, execute it directly with `mcp__databricks__run_sql`
2. If the user described what they want in natural language, first understand the relevant tables using `describe_table`, then build and execute the SQL query
3. Present the results formatted as a markdown table
4. If relevant, add observations about the returned data (trends, outliers, totals)

## User input

$ARGUMENTS
