---
description: Feature analysis and feature engineering pipeline generation
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__sample_table, mcp__databricks__table_stats, mcp__databricks__list_tables, mcp__databricks__list_schemas
---

The user wants to analyze features of a table or generate a feature engineering pipeline.

## Instructions

### 1. Understand the data
- Use `describe_table` to list columns and types
- Use `table_stats` for cardinality and nulls
- Use `sample_table` to view actual data
- Identify the target variable if provided

### 2. Feature analysis via SQL

Execute the following analyses with `run_sql`:

#### Typing and cardinality
- Classify each column: continuous numeric, discrete numeric, categorical, temporal, text
- Evaluate cardinality to decide encoding strategy

#### Correlation with target (if provided)
```sql
SELECT CORR(feature_numerica, target) as correlacao
FROM tabela
```

#### Categorical distribution
```sql
SELECT coluna, COUNT(*) as freq,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM tabela
GROUP BY coluna
ORDER BY freq DESC
LIMIT 20
```

#### Null analysis
```sql
SELECT
  COUNT(*) as total,
  SUM(CASE WHEN col IS NULL THEN 1 ELSE 0 END) as nulos,
  ROUND(SUM(CASE WHEN col IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pct_nulos
FROM tabela
```

#### Predictive power of each feature (approximate Information Value)
- For each feature, calculate the separation between target classes
- Identify features with the highest predictive power

### 3. Recommend transformations

Based on the analysis, recommend:

- **Numeric**: scaling (StandardScaler, MinMaxScaler), log transform for skewed distributions, binning
- **Categorical**: one-hot (low cardinality), target encoding (high cardinality), frequency encoding
- **Temporal**: extract year, month, day, day of week, quarter, holidays
- **Window features**: moving averages, lags, diffs, rolling min/max/std
- **Interactions**: ratios between features, multiplications, polynomial features
- **Nulls**: imputation by mean/median/mode, missing flag

### 4. Generate feature engineering notebook (if requested)

Create a `.py` notebook in Databricks format with:

- **Cell 1**: Imports and data loading
- **Cell 2**: Feature exploratory analysis
- **Cell 3**: Null handling
- **Cell 4**: Categorical encoding
- **Cell 5**: Numeric transformations
- **Cell 6**: Temporal features and window features
- **Cell 7**: Feature selection (correlation filter, variance threshold)
- **Cell 8**: Save feature dataset as a Delta table

### 5. Output format

- Present analysis organized by feature type
- Rank features by relevance (if target is provided)
- List recommended transformations in table format
- If generating a notebook, use Databricks format

## User input

$ARGUMENTS
