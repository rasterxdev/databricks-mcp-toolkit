---
description: Review Databricks infrastructure and generate optimization recommendations
allowed-tools: mcp__databricks__list_clusters, mcp__databricks__list_warehouses, mcp__databricks__list_jobs, mcp__databricks__list_job_runs, mcp__databricks__list_pipelines, mcp__databricks__run_sql
---

The user wants to review their Databricks infrastructure and get optimization recommendations.

## Instructions

1. **Compute inventory**: use `list_clusters` to list all clusters. Note states (RUNNING, TERMINATED), node types, autoscaling settings, and Spark versions.

2. **SQL Warehouses**: use `list_warehouses` to list all warehouses. Note states, types (CLASSIC, PRO, SERVERLESS), and sizes.

3. **Workflows**: use `list_jobs` to list all jobs. For the most critical ones (or recently failed), use `list_job_runs` to check run history and failure rates.

4. **DLT Pipelines**: use `list_pipelines` to list all Delta Live Tables pipelines and their states.

5. **Cost analysis** (if system tables are available): query `system.billing.usage` for cost breakdown:
   ```sql
   SELECT sku_name, usage_unit,
          SUM(usage_quantity) as total_usage,
          SUM(usage_quantity * list_price) as estimated_cost
   FROM system.billing.usage
   WHERE datediff(current_date(), usage_date) <= 30
   GROUP BY 1, 2
   ORDER BY estimated_cost DESC
   LIMIT 20
   ```

6. **Generate infrastructure health report** with:
   - **Inventory summary**: counts of clusters, warehouses, jobs, pipelines
   - **Idle resources**: clusters running with no recent activity, oversized warehouses
   - **Job health**: failure rates, long-running jobs, jobs without retry policies
   - **Cost insights**: top cost drivers, cost trends, waste identification
   - **Optimization recommendations**: specific actions with effort estimates (low/medium/high) and expected impact

## User input

$ARGUMENTS
