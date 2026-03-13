---
description: Manage and inspect MLflow experiments, runs, models, and endpoints
allowed-tools: mcp__databricks__list_experiments, mcp__databricks__get_experiment_runs, mcp__databricks__get_run_details, mcp__databricks__compare_runs, mcp__databricks__get_metric_history, mcp__databricks__list_registered_models, mcp__databricks__get_model_versions, mcp__databricks__list_serving_endpoints, mcp__databricks__get_serving_endpoint, mcp__databricks__run_sql
---

The user wants to inspect or manage ML resources on Databricks (MLflow experiments, runs, models, endpoints).

## Instructions

Interpret the user's command and execute the appropriate action:

### List experiments
- Use `list_experiments` to show available experiments
- Example: `/model list experiments`

### Explore runs of an experiment
- Use `get_experiment_runs` with the experiment ID
- Show summarized metrics and parameters
- Example: `/model runs <experiment_id>`

### Run details
- Use `get_run_details` to view parameters, metrics, tags, and artifacts
- Example: `/model run <run_id>`

### Compare runs
- Use `compare_runs` with comma-separated IDs
- Highlight the best model based on metrics
- Example: `/model compare <run_id1>,<run_id2>`

### Metric history
- Use `get_metric_history` to view the evolution of a metric
- Analyze convergence and overfitting
- Example: `/model history <run_id> loss`

### List registered models
- Use `list_registered_models` to view models in the Registry
- Example: `/model list models`

### Model versions
- Use `get_model_versions` to view versions of a specific model
- Example: `/model versions <catalog.schema.model_name>`

### Serving endpoints
- Use `list_serving_endpoints` to list endpoints
- Use `get_serving_endpoint` for details on a specific endpoint
- Example: `/model endpoints` or `/model endpoint <name>`

## Output format

- Format results as markdown tables
- When comparing runs, highlight the best result
- When analyzing metric history, comment on convergence
- Suggest next steps when relevant

## User input

$ARGUMENTS
