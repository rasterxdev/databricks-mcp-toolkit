---
description: Create a data ingestion pipeline notebook for Databricks
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table, mcp__databricks__list_catalogs, mcp__databricks__list_schemas, mcp__databricks__list_tables, mcp__databricks__sample_table, Read, Write, Edit
---

The user wants to create a data ingestion pipeline notebook for Databricks.

## Instructions

1. **Identify source type**: determine the data source from user input:
   - **Files**: CSV, JSON, Parquet, Avro, XML (cloud storage or DBFS)
   - **Database**: JDBC/ODBC (SQL Server, PostgreSQL, MySQL, Oracle)
   - **API**: REST/RESTful endpoints
   - **Streaming**: Kafka, RabbitMQ, Event Hubs, Kinesis

2. **Understand target**: if a target table exists, use `describe_table` to understand the schema. Otherwise, design the target table structure.

3. **Generate a Databricks notebook** (`.py` format) with these cells:

   #### Cell 1: Configuration
   - Imports (pyspark.sql, delta, dbutils)
   - Source connection parameters (use widgets or dbutils.secrets for credentials)
   - Target table name and write mode

   #### Cell 2: Read from source
   - **Files**: `spark.readStream.format("cloudFiles")` with Auto Loader for incremental, `spark.read.format()` for batch
   - **JDBC**: `spark.read.format("jdbc").option("url", ...).option("dbtable", ...).option("partitionColumn", ...)` with parallel reads
   - **API**: Python `requests` with pagination, convert to DataFrame
   - **Kafka**: `spark.readStream.format("kafka").option("subscribe", topic)`

   #### Cell 3: Schema validation & data quality
   - Validate schema against expected structure
   - Check for nulls in required columns
   - Apply data type casting
   - Log quality metrics (total rows, valid rows, rejected rows)

   #### Cell 4: Transformations
   - Add metadata columns: `_ingested_at`, `_source_file` (for files), `_batch_id`
   - Deduplication logic (if applicable)
   - Type conversions and normalization

   #### Cell 5: Write to Delta
   - **Append**: `.writeStream.format("delta").outputMode("append")` or `.write.mode("append")`
   - **Merge/Upsert**: `DeltaTable.forName().merge()` with match conditions
   - **Overwrite**: `.write.mode("overwrite").option("overwriteSchema", "true")`
   - Set appropriate checkpoint location for streaming

   #### Cell 6: Post-ingestion validation
   - Row count verification
   - Schema drift detection
   - Sample data preview

4. **Medallion placement**:
   - Bronze: raw data, append-only, no transformations except metadata
   - Silver: cleaned, deduplicated, typed, ready for joins
   - Gold: aggregated, business-ready, optimized for queries

5. **Best practices to include**:
   - Use `dbutils.secrets` for credentials, never hardcode
   - Partition by date for time-series data
   - Set Auto Loader schema hints for CSV/JSON
   - Use checkpoints for exactly-once streaming guarantees
   - Include OPTIMIZE and VACUUM recommendations as comments

## User input

$ARGUMENTS
