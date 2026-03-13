---
description: Run statistical tests and advanced analyses via SQL on Databricks
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__sample_table, mcp__databricks__table_stats, mcp__databricks__list_tables
---

The user wants an advanced statistical analysis of data on Databricks.

## Instructions

### 1. Understand the data
- Use `describe_table` to understand columns and types
- Use `table_stats` for an overview
- Identify relevant numeric and categorical columns

### 2. Run analyses via SQL

Depending on the user's request, execute one or more of the following analyses using `run_sql`:

#### Advanced descriptive statistics
```sql
SELECT
  COUNT(*) as n,
  AVG(coluna) as media,
  STDDEV(coluna) as desvio_padrao,
  VARIANCE(coluna) as variancia,
  SKEWNESS(coluna) as assimetria,
  KURTOSIS(coluna) as curtose,
  MIN(coluna) as minimo,
  PERCENTILE(coluna, 0.25) as q1,
  PERCENTILE(coluna, 0.50) as mediana,
  PERCENTILE(coluna, 0.75) as q3,
  MAX(coluna) as maximo
FROM tabela
```

#### Correlation between variables
```sql
SELECT
  CORR(col_a, col_b) as correlacao
FROM tabela
```

#### Outlier detection (IQR)
```sql
WITH stats AS (
  SELECT
    PERCENTILE(coluna, 0.25) as q1,
    PERCENTILE(coluna, 0.75) as q3
  FROM tabela
)
SELECT COUNT(*) as outliers
FROM tabela, stats
WHERE coluna < q1 - 1.5 * (q3 - q1)
   OR coluna > q3 + 1.5 * (q3 - q1)
```

#### Frequency distribution
```sql
SELECT
  coluna,
  COUNT(*) as frequencia,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentual
FROM tabela
GROUP BY coluna
ORDER BY frequencia DESC
```

#### Approximate normality test
- Use skewness and kurtosis to assess normality
- Skewness close to 0 and kurtosis close to 3 indicate a normal distribution

### 3. Output format

- Present results organized with markdown headers
- Interpret the results statistically (what the numbers mean)
- Include recommendations based on findings
- If relevant, suggest next analysis steps

## User input

$ARGUMENTS
