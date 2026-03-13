---
description: Time series analysis and forecasting notebook generation
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__sample_table, mcp__databricks__table_stats, mcp__databricks__list_tables, mcp__databricks__list_experiments
---

The user wants to analyze a time series or create a forecasting notebook.

## Instructions

### 1. Understand the temporal data
- Use `describe_table` to identify date columns and metrics
- Use `sample_table` to see the data format
- Identify the temporal granularity (daily, weekly, monthly)

### 2. Temporal exploratory analysis via SQL

Execute the following analyses with `run_sql`:

#### Period and coverage
```sql
SELECT
  MIN(data_col) as inicio,
  MAX(data_col) as fim,
  COUNT(*) as registros,
  COUNT(DISTINCT data_col) as periodos_unicos
FROM tabela
```

#### Trend (moving averages)
```sql
SELECT
  data_col,
  valor,
  AVG(valor) OVER (ORDER BY data_col ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as mm3,
  AVG(valor) OVER (ORDER BY data_col ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) as mm12
FROM tabela
ORDER BY data_col
```

#### Seasonality
```sql
SELECT
  MONTH(data_col) as mes,
  AVG(valor) as media,
  STDDEV(valor) as desvio
FROM tabela
GROUP BY MONTH(data_col)
ORDER BY mes
```

#### Period-over-period variation
```sql
SELECT
  data_col,
  valor,
  LAG(valor) OVER (ORDER BY data_col) as valor_anterior,
  valor - LAG(valor) OVER (ORDER BY data_col) as variacao,
  ROUND((valor - LAG(valor) OVER (ORDER BY data_col)) / LAG(valor) OVER (ORDER BY data_col) * 100, 2) as var_pct
FROM tabela
ORDER BY data_col
```

#### Temporal anomaly detection
```sql
WITH stats AS (
  SELECT AVG(valor) as media, STDDEV(valor) as desvio
  FROM tabela
)
SELECT t.*, (t.valor - s.media) / s.desvio as z_score
FROM tabela t, stats s
WHERE ABS((t.valor - s.media) / s.desvio) > 2
ORDER BY t.data_col
```

### 3. Generate forecasting notebook (if requested)

Create a `.py` notebook in Databricks format with:

- **Cell 1**: Imports (pandas, prophet or statsmodels, mlflow, matplotlib)
- **Cell 2**: Data loading and preparation
- **Cell 3**: Time series visualization (trend, seasonality)
- **Cell 4**: Decomposition (trend, seasonal, residual)
- **Cell 5**: Forecasting model with MLflow logging
- **Cell 6**: Predictions and confidence intervals
- **Cell 7**: Evaluation metrics (RMSE, MAE, MAPE)

### 4. Output format

- Present findings on trend, seasonality, and anomalies
- Interpret the patterns found
- If generating a notebook, save as `.py` in Databricks format

## User input

$ARGUMENTS
