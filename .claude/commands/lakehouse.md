---
description: Review lakehouse environment architecture and generate an improvement plan
allowed-tools: mcp__databricks__run_sql, mcp__databricks__list_catalogs, mcp__databricks__list_schemas, mcp__databricks__list_tables, mcp__databricks__describe_table, mcp__databricks__table_stats, mcp__databricks__list_warehouses, mcp__databricks__list_clusters, mcp__databricks__list_jobs, mcp__databricks__list_pipelines, mcp__databricks__get_grants, mcp__databricks__get_effective_grants, Read, Write, Edit
---

The user wants a comprehensive review of their Databricks Lakehouse environment with an improvement plan.

## Instructions

1. **Catalog inventory**: use `list_catalogs` -> `list_schemas` for each catalog -> `list_tables` for each schema. Build a full inventory with counts.

2. **Architecture assessment**:
   - Evaluate medallion layer compliance: check if naming conventions follow bronze/silver/gold (or raw/curated/consumption) patterns
   - Check catalog/schema organization: is there a clear separation by domain, layer, or environment?
   - Review table types: managed vs external, Delta vs other formats

3. **Data quality assessment**: for key tables (largest, most referenced):
   - Use `describe_table` to review schema (types, nullability, comments)
   - Use `table_stats` to check nulls, cardinality, and row counts
   - Look for: missing comments, no partitioning hints, inconsistent naming

4. **Governance review**:
   - Use `get_grants` on top-level catalogs to understand permission structure
   - Check if there is a clear ownership model (who owns each catalog/schema)
   - Identify overly permissive grants

5. **Compute and orchestration review**:
   - `list_clusters` -> evaluate sizing, autoscaling, Spark versions
   - `list_warehouses` -> check types (serverless vs classic) and sizing
   - `list_jobs` -> evaluate automation coverage
   - `list_pipelines` -> DLT adoption

6. **Performance indicators** (if system tables are available):
   - Query `system.billing.usage` for cost trends
   - Query `system.access.audit` for usage patterns
   - Review query history via `run_sql` for slow queries

7. **Generate improvement plan** with these sections:

   ### Current State Summary
   - Total catalogs, schemas, tables (with breakdown)
   - Compute inventory (clusters, warehouses, pipelines)
   - Orchestration overview (jobs count, failure rates)

   ### Architecture Compliance Score
   - Medallion adherence (bronze/silver/gold naming: yes/partial/no)
   - Naming consistency (score: 1-5)
   - Documentation quality (table/column comments: % coverage)

   ### Findings & Recommendations
   For each finding:
   - **Issue**: what was found
   - **Impact**: why it matters (performance, cost, governance, reliability)
   - **Recommendation**: specific action to take
   - **Effort**: low / medium / high
   - **Priority**: P1 (critical) / P2 (important) / P3 (nice-to-have)

   Categories to cover:
   - Table optimization (partitioning, Z-ordering, liquid clustering)
   - Table maintenance (vacuum, optimize schedules)
   - Schema improvements (types, nullability, comments)
   - Governance gaps (permissions, ownership, classification)
   - Compute optimization (right-sizing, autoscaling, serverless migration)
   - Cost reduction opportunities
   - Observability gaps (monitoring, alerting, lineage)

## User input

$ARGUMENTS
