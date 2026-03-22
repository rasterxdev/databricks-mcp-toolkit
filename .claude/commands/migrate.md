---
description: Generate a migration plan from another data platform to Databricks Lakehouse
allowed-tools: mcp__databricks__run_sql, mcp__databricks__list_catalogs, mcp__databricks__list_schemas, mcp__databricks__list_tables, mcp__databricks__describe_table, mcp__databricks__list_warehouses, Read, Write, Edit
---

The user wants to plan or execute a migration from another data platform to Databricks.

## Instructions

1. **Identify source platform and scope**: determine the source (Snowflake, BigQuery, Redshift, SQL Server, Oracle, PostgreSQL, etc.) and what needs to be migrated (schemas, tables, views, stored procedures, pipelines).

2. **Analyze source schema**: if the user provides DDL files, schema exports, or descriptions, read them to understand the source structure. Map every data type to its Databricks/Delta equivalent.

3. **Design target medallion architecture**:
   - **Bronze** (raw): land data as-is from source, add ingestion metadata (`_ingested_at`, `_source_file`)
   - **Silver** (cleaned): apply type casting, deduplication, null handling, schema enforcement
   - **Gold** (business): aggregated/modeled tables ready for analytics

4. **Generate Unity Catalog structure**: propose catalogs, schemas, and tables following naming conventions:
   ```
   <environment>_<domain>.<layer>.<entity>
   Example: prod_sales.bronze.raw_orders
   ```

5. **Create migration artifacts**:
   - **Data type mapping table**: source type -> Delta type for every column
   - **DDL scripts**: CREATE TABLE statements for target Delta tables
   - **Ingestion notebook** (.py Databricks format): PySpark code to read from source and write to bronze
   - **Transformation notebook**: bronze -> silver -> gold transformations
   - **Validation queries**: row count comparisons, checksum validation, sample data comparison

6. **Migration checklist**: generate a step-by-step migration plan with:
   - Pre-migration (access setup, network connectivity, credential configuration)
   - Data transfer (batch sizes, parallelism, incremental vs full load)
   - Validation (data integrity checks, business logic verification)
   - Cutover (switch traffic, decommission source)
   - Rollback plan (how to revert if issues are found)

7. **Platform-specific guidance**:
   - **Snowflake**: VARIANT -> STRING, TIMESTAMP_LTZ -> TIMESTAMP, FLATTEN -> explode(), JavaScript UDFs -> Python UDFs
   - **BigQuery**: STRUCT -> STRUCT, ARRAY -> ARRAY, PARTITION BY -> Delta partitioning, scheduled queries -> Databricks jobs
   - **Redshift**: DISTKEY/SORTKEY -> Z-ORDER/partitioning, COPY -> Auto Loader, spectrum -> Unity Catalog external tables
   - **SQL Server**: NVARCHAR -> STRING, IDENTITY -> GENERATED ALWAYS AS IDENTITY, stored procedures -> notebooks/dbt

## User input

$ARGUMENTS
