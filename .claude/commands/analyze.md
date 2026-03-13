---
description: Complete exploratory data analysis of a Databricks table
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__sample_table, mcp__databricks__table_stats, mcp__databricks__list_tables, mcp__databricks__list_schemas
---

The user wants an exploratory data analysis (EDA) of a table on Databricks.

## Instructions

Perform the analysis in the following order:

1. **Schema**: Use `describe_table` to list columns, types, and comments
2. **Statistics**: Use `table_stats` for counts, nulls, and cardinality
3. **Sample**: Use `sample_table` to view actual records
4. **Distributions**: Execute SQL queries for:
   - Value distribution in categorical columns (GROUP BY + COUNT)
   - MIN, MAX, AVG, STDDEV on numeric columns
   - Temporal distribution if date columns are present
5. **Data Quality**: Check for:
   - Null percentage per column
   - Possible duplicates
   - Unexpected values

## Output format

Present the results organized with clear markdown headers.
Include a final "Observations" section with any insights found.

## User input

$ARGUMENTS
