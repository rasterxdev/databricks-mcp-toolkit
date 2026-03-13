---
description: Create a Python/PySpark notebook in Databricks format
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__sample_table, mcp__databricks__table_stats, Read, Write, Edit
---

The user wants to create a Python or PySpark notebook in Databricks format.

## Instructions

1. If the user referenced tables, use `describe_table` to understand their schemas
2. Create the notebook as a `.py` file using Databricks format:
   - First line: `# Databricks notebook source`
   - Cell separator: `# COMMAND ----------`
3. Structure the notebook with:
   - Imports and configuration cell
   - Documentation cell (markdown with `# MAGIC %md`)
   - Logic cells with explanatory comments
   - Validation/verification cell at the end
4. Save the file in the project directory

## Code standards

- Use `spark.read.table("catalog.schema.table")` to read tables
- Prefer DataFrame API for complex transformations
- Use `display()` to show results
- Use `# MAGIC %md` for markdown documentation cells
- Handle errors with try/except where necessary

## User input

$ARGUMENTS
