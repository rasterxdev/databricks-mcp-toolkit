---
description: Create a notebook with a complete ML pipeline (EDA, features, training, evaluation, MLflow)
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__sample_table, mcp__databricks__table_stats, mcp__databricks__list_tables, mcp__databricks__list_schemas, mcp__databricks__list_experiments, mcp__databricks__get_experiment_runs
---

The user wants to create a complete Machine Learning pipeline as a Databricks notebook.

## Instructions

### 1. Understand the problem
- Identify the data table, target variable, and problem type (classification or regression)
- If the user did not specify a table, ask for one
- Use `describe_table` and `sample_table` to understand the data

### 2. Generate a notebook with a complete pipeline

Create a `.py` file in Databricks notebook format with the following cells:

#### Cell 1: Setup and imports
```python
# Databricks notebook source
import mlflow
import mlflow.sklearn
from pyspark.sql import functions as F
from sklearn.model_selection import train_test_split
from sklearn.metrics import *
import pandas as pd
import numpy as np
```

#### Cell 2: Data loading
- Read the table with Spark
- Display schema and row count

#### Cell 3: EDA (Exploratory Data Analysis)
- Descriptive statistics
- Target variable distribution
- Null check and class balance assessment

#### Cell 4: Feature Engineering
- Null handling
- Categorical encoding
- Numeric scaling
- Feature selection

#### Cell 5: Train/test split
- Stratified split (for classification)
- 80/20 ratio, or temporal split if data has a time component

#### Cell 6: Training with MLflow
- Configure MLflow experiment
- Train model(s) with parameter and metric logging
- Use `mlflow.autolog()` or manual logging

#### Cell 7: Evaluation
- Metrics on the test set
- Confusion matrix (classification) or scatter plot (regression)
- Feature importance

#### Cell 8: Model registration (optional)
- Register in Unity Catalog Model Registry if results are satisfactory

### 3. Notebook format

- Use `# COMMAND ----------` between cells
- Use `# MAGIC %md` for documentation cells
- Document each step with markdown cells
- Include `display()` for visualizations in Databricks

## User input

$ARGUMENTS
