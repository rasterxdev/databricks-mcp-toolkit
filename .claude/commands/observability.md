---
description: Monitor and analyze Databricks workspace using system tables
allowed-tools: mcp__databricks__run_sql, mcp__databricks__list_warehouses, mcp__databricks__list_jobs, mcp__databricks__list_job_runs, mcp__databricks__list_clusters
---

The user wants to monitor and analyze their Databricks workspace using system tables and MCP tools.

## Instructions

1. **Determine monitoring scope**: ask or infer which aspects to monitor:
   - **billing** — cost trends and anomalies
   - **access** — login patterns and data access
   - **compute** — cluster and warehouse utilization
   - **workflows** — job success rates and duration
   - **lineage** — data flow and dependencies
   - **all** — comprehensive overview

2. **Billing analysis** (query `system.billing.usage`):
   ```sql
   -- Cost trend (last 30 days by SKU)
   SELECT usage_date, sku_name,
          SUM(usage_quantity) as total_dbu,
          SUM(usage_quantity * list_price) as estimated_cost
   FROM system.billing.usage
   WHERE datediff(current_date(), usage_date) <= 30
   GROUP BY 1, 2
   ORDER BY 1 DESC, estimated_cost DESC
   ```
   - Identify top cost drivers, cost spikes, and trends
   - Compare weekday vs weekend usage

3. **Access audit** (query `system.access.audit`):
   ```sql
   -- Top actions (last 7 days)
   SELECT action_name, user_identity.email, COUNT(*) as count
   FROM system.access.audit
   WHERE datediff(current_date(), event_date) <= 7
   GROUP BY 1, 2
   ORDER BY count DESC
   LIMIT 30
   ```
   - Identify unusual access patterns
   - Track API calls and data access frequency

4. **Compute utilization** (use `list_clusters` + system tables):
   - List active clusters and their states
   - Query `system.compute.clusters` for utilization metrics if available
   - Identify idle clusters consuming resources

5. **Workflow health** (use `list_jobs` + `list_job_runs` + system tables):
   - List recent job runs with success/failure rates
   - Query `system.lakeflow.job_run_timeline` if available:
   ```sql
   SELECT job_id, result_state, COUNT(*) as run_count,
          AVG(UNIX_TIMESTAMP(period_end_time) - UNIX_TIMESTAMP(period_start_time)) as avg_duration_sec
   FROM system.lakeflow.job_run_timeline
   WHERE datediff(current_date(), period_start_time) <= 7
   GROUP BY 1, 2
   ORDER BY run_count DESC
   ```
   - Identify failing jobs, SLA breaches, and long-running tasks

6. **Data lineage** (if available):
   ```sql
   -- Table-level lineage
   SELECT source_table_full_name, target_table_full_name,
          COUNT(*) as lineage_count
   FROM system.access.table_lineage
   WHERE datediff(current_date(), event_date) <= 30
   GROUP BY 1, 2
   ORDER BY lineage_count DESC
   LIMIT 30
   ```

7. **Generate monitoring report** with:
   - KPI summary (total cost, active clusters, job success rate, top users)
   - Trend charts descriptions (cost over time, jobs over time)
   - Anomalies and alerts (spikes, failures, unusual access)
   - Actionable recommendations
   - Optionally: generate a monitoring notebook that can be scheduled as a daily/weekly job

## User input

$ARGUMENTS
