"""
MCP Server for Databricks (HTTP transport).

Stateless server that receives Databricks credentials per-request via HTTP headers.
Designed to be deployed on Railway, Fly.io, Render, or any container platform.

Each user configures their own DATABRICKS_HOST and DATABRICKS_TOKEN locally.
The Claude Code MCP client sends these as headers with every tool call.

Usage:
    python databricks_mcp/server.py
"""

import contextvars
import hashlib
import os
import threading
import time
from datetime import datetime, timezone
from textwrap import dedent

from databricks.sdk import WorkspaceClient
from mcp.server.fastmcp import FastMCP
from starlette.requests import Request
from starlette.responses import JSONResponse

# ---------------------------------------------------------------------------
# Per-request credentials (populated by ASGI middleware on each HTTP request)
# ---------------------------------------------------------------------------

_db_host = contextvars.ContextVar("db_host", default="")
_db_token = contextvars.ContextVar("db_token", default="")
_db_warehouse_id = contextvars.ContextVar("db_warehouse_id", default="")

# ---------------------------------------------------------------------------
# Client & warehouse caches (shared across requests, thread-safe)
# ---------------------------------------------------------------------------

_client_cache: dict[str, WorkspaceClient] = {}
_client_lock = threading.Lock()

_warehouse_cache: dict[str, tuple[str, float]] = {}
_warehouse_lock = threading.Lock()
_WAREHOUSE_TTL = 300  # 5 minutes

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

mcp = FastMCP(
    "Databricks",
    instructions=dedent("""
        MCP server for Databricks interaction.
        Allows executing SQL, exploring catalogs/schemas/tables,
        and managing workspace resources via Unity Catalog, MLflow,
        and Model Serving.
    """).strip(),
)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@mcp.custom_route("/health", methods=["GET"])
async def health_check(request: Request) -> JSONResponse:
    return JSONResponse({"status": "ok", "service": "databricks-mcp"})


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_client() -> WorkspaceClient:
    """Return a WorkspaceClient for the current request's credentials (cached)."""
    host = _db_host.get()
    token = _db_token.get()
    if not host or not token:
        raise RuntimeError(
            "Missing Databricks credentials. "
            "Configure X-Databricks-Host and X-Databricks-Token headers "
            "in your .mcp.json."
        )
    key = hashlib.sha256(f"{host}:{token}".encode()).hexdigest()[:16]
    with _client_lock:
        if key not in _client_cache:
            _client_cache[key] = WorkspaceClient(host=host, token=token)
        return _client_cache[key]


def _get_warehouse_id() -> str:
    """Return the warehouse ID for the current request (cached with TTL)."""
    wh_id = _db_warehouse_id.get()
    if wh_id:
        return wh_id

    host = _db_host.get()
    token = _db_token.get()
    cache_key = f"{host}:{token[:8]}"
    now = time.time()

    with _warehouse_lock:
        if cache_key in _warehouse_cache:
            cached_id, cached_time = _warehouse_cache[cache_key]
            if now - cached_time < _WAREHOUSE_TTL:
                return cached_id

    client = _get_client()
    warehouses = list(client.warehouses.list())
    for wh in warehouses:
        if str(wh.state) == "State.RUNNING":
            with _warehouse_lock:
                _warehouse_cache[cache_key] = (wh.id, now)
            return wh.id
    if warehouses:
        with _warehouse_lock:
            _warehouse_cache[cache_key] = (warehouses[0].id, now)
        return warehouses[0].id
    raise RuntimeError("No SQL Warehouse found in the workspace.")


# ---------------------------------------------------------------------------
# Tools — Data & SQL
# ---------------------------------------------------------------------------

@mcp.tool()
def run_sql(query: str, max_rows: int = 100) -> str:
    """Execute a SQL query on Databricks and return the results.

    Args:
        query: SQL query to execute.
        max_rows: Maximum number of rows to return (default: 100).
    """
    client = _get_client()
    wh_id = _get_warehouse_id()

    result = client.statement_execution.execute_statement(
        warehouse_id=wh_id,
        statement=query,
        wait_timeout="50s",
        row_limit=max_rows,
    )

    status = result.status
    if status and status.error:
        return f"ERROR: {status.error.message}"

    if not result.manifest or not result.manifest.schema:
        return "Query executed successfully (no results)."

    columns = [col.name for col in result.manifest.schema.columns]
    rows = result.result.data_array if result.result and result.result.data_array else []

    lines = []
    lines.append("| " + " | ".join(columns) + " |")
    lines.append("| " + " | ".join("---" for _ in columns) + " |")
    for row in rows:
        lines.append("| " + " | ".join(str(v) if v is not None else "NULL" for v in row) + " |")

    total = result.manifest.total_row_count
    if total and total > max_rows:
        lines.append(f"\n*Showing {max_rows} of {total} rows. Use max_rows to see more.*")

    return "\n".join(lines)


@mcp.tool()
def list_catalogs() -> str:
    """List all available catalogs in Unity Catalog."""
    client = _get_client()
    catalogs = list(client.catalogs.list())
    if not catalogs:
        return "No catalogs found."
    lines = ["| Catalog | Type | Comment |", "| --- | --- | --- |"]
    for cat in catalogs:
        comment = (cat.comment or "")[:80]
        cat_type = str(cat.catalog_type) if cat.catalog_type else "-"
        lines.append(f"| {cat.name} | {cat_type} | {comment} |")
    return "\n".join(lines)


@mcp.tool()
def list_schemas(catalog: str) -> str:
    """List all schemas in a catalog.

    Args:
        catalog: Catalog name.
    """
    client = _get_client()
    schemas = list(client.schemas.list(catalog_name=catalog))
    if not schemas:
        return f"No schemas found in catalog '{catalog}'."
    lines = ["| Schema | Comment |", "| --- | --- |"]
    for s in schemas:
        comment = (s.comment or "")[:80]
        lines.append(f"| {s.name} | {comment} |")
    return "\n".join(lines)


@mcp.tool()
def list_tables(catalog: str, schema: str) -> str:
    """List all tables in a schema.

    Args:
        catalog: Catalog name.
        schema: Schema name.
    """
    client = _get_client()
    tables = list(client.tables.list(catalog_name=catalog, schema_name=schema))
    if not tables:
        return f"No tables found in '{catalog}.{schema}'."
    lines = ["| Table | Type | Comment |", "| --- | --- | --- |"]
    for t in tables:
        ttype = str(t.table_type).split(".")[-1] if t.table_type else "-"
        comment = (t.comment or "")[:80]
        lines.append(f"| {t.name} | {ttype} | {comment} |")
    return "\n".join(lines)


@mcp.tool()
def describe_table(full_table_name: str) -> str:
    """Return the detailed schema of a table (columns, types, comments).

    Args:
        full_table_name: Fully qualified table name (catalog.schema.table).
    """
    client = _get_client()
    table = client.tables.get(full_name=full_table_name)

    lines = [f"## {table.full_name}\n"]

    if table.comment:
        lines.append(f"**Description:** {table.comment}\n")

    ttype = str(table.table_type).split(".")[-1] if table.table_type else "-"
    lines.append(f"**Type:** {ttype}")

    if table.storage_location:
        lines.append(f"**Storage:** {table.storage_location}")

    lines.append("")
    lines.append("| Column | Type | Nullable | Comment |")
    lines.append("| --- | --- | --- | --- |")

    if table.columns:
        for col in table.columns:
            nullable = "Yes" if col.nullable else "No"
            comment = (col.comment or "")[:60]
            lines.append(f"| {col.name} | {col.type_name} | {nullable} | {comment} |")

    return "\n".join(lines)


@mcp.tool()
def sample_table(full_table_name: str, rows: int = 10) -> str:
    """Return a sample of data from a table.

    Args:
        full_table_name: Fully qualified table name (catalog.schema.table).
        rows: Number of rows to return (default: 10).
    """
    query = f"SELECT * FROM `{full_table_name.replace('.', '`.`')}` LIMIT {rows}"
    return run_sql(query, max_rows=rows)


@mcp.tool()
def table_stats(full_table_name: str) -> str:
    """Return basic statistics for a table (count, nulls, distinct).

    Args:
        full_table_name: Fully qualified table name (catalog.schema.table).
    """
    client = _get_client()
    table = client.tables.get(full_name=full_table_name)

    if not table.columns:
        return "Table has no defined columns."

    escaped = f"`{full_table_name.replace('.', '`.`')}`"

    count_result = run_sql(f"SELECT COUNT(*) as total FROM {escaped}", max_rows=1)

    col_stats = []
    for col in table.columns[:20]:
        name = col.name
        col_stats.append(
            f"COUNT(DISTINCT `{name}`) as `{name}_distinct`, "
            f"SUM(CASE WHEN `{name}` IS NULL THEN 1 ELSE 0 END) as `{name}_nulls`"
        )

    stats_query = f"SELECT {', '.join(col_stats)} FROM {escaped}"
    stats_result = run_sql(stats_query, max_rows=1)

    return f"### Row Count\n{count_result}\n\n### Per-Column Statistics\n{stats_result}"


@mcp.tool()
def list_warehouses() -> str:
    """List all available SQL Warehouses in the workspace."""
    client = _get_client()
    warehouses = list(client.warehouses.list())
    if not warehouses:
        return "No SQL Warehouses found."
    lines = ["| ID | Name | State | Type |", "| --- | --- | --- | --- |"]
    for wh in warehouses:
        state = str(wh.state).split(".")[-1] if wh.state else "-"
        wh_type = str(wh.warehouse_type).split(".")[-1] if wh.warehouse_type else "-"
        lines.append(f"| {wh.id} | {wh.name} | {state} | {wh_type} |")
    return "\n".join(lines)


@mcp.tool()
def query_history(max_results: int = 10) -> str:
    """List recent queries executed in the workspace.

    Args:
        max_results: Maximum number of queries to return (default: 10).
    """
    client = _get_client()
    from databricks.sdk.service.sql import ListQueryHistoryRequest

    history = client.query_history.list(request=ListQueryHistoryRequest())

    lines = ["| Query ID | Status | Duration (ms) | Warehouse |", "| --- | --- | --- | --- |"]
    count = 0
    for q in history:
        if count >= max_results:
            break
        status = str(q.status).split(".")[-1] if q.status else "-"
        duration = q.execution_end_time_ms - q.query_start_time_ms if q.execution_end_time_ms and q.query_start_time_ms else "-"
        lines.append(f"| {q.query_id} | {status} | {duration} | {q.warehouse_id} |")
        count += 1

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Tools — MLflow & Model Registry
# ---------------------------------------------------------------------------

@mcp.tool()
def list_experiments(max_results: int = 20) -> str:
    """List MLflow experiments in the workspace.

    Args:
        max_results: Maximum number of experiments to return (default: 20).
    """
    client = _get_client()
    experiments = list(client.experiments.list_experiments())

    if not experiments:
        return "No experiments found."

    lines = ["| ID | Name | Lifecycle |", "| --- | --- | --- |"]
    count = 0
    for exp in experiments:
        if count >= max_results:
            break
        lifecycle = str(exp.lifecycle_stage) if exp.lifecycle_stage else "-"
        lines.append(f"| {exp.experiment_id} | {exp.name} | {lifecycle} |")
        count += 1

    return "\n".join(lines)


@mcp.tool()
def get_experiment_runs(experiment_id: str, max_results: int = 20) -> str:
    """List runs of an MLflow experiment with metrics and parameters.

    Args:
        experiment_id: MLflow experiment ID.
        max_results: Maximum number of runs to return (default: 20).
    """
    client = _get_client()
    response = client.experiments.search_runs(
        experiment_ids=[experiment_id],
        max_results=max_results,
    )

    runs = response.runs if response.runs else []
    if not runs:
        return f"No runs found for experiment '{experiment_id}'."

    lines = ["| Run ID | Status | Start Time | Metrics | Parameters |",
             "| --- | --- | --- | --- | --- |"]

    for run in runs:
        info = run.info
        run_id = info.run_id if info else "-"
        status = str(info.status) if info and info.status else "-"

        start = "-"
        if info and info.start_time:
            start = datetime.fromtimestamp(
                info.start_time / 1000, tz=timezone.utc
            ).strftime("%Y-%m-%d %H:%M")

        metrics_str = "-"
        if run.data and run.data.metrics:
            top = list(run.data.metrics)[:5]
            metrics_str = ", ".join(f"{m.key}={m.value:.4g}" for m in top)

        params_str = "-"
        if run.data and run.data.params:
            top_p = list(run.data.params)[:5]
            params_str = ", ".join(f"{p.key}={p.value}" for p in top_p)

        lines.append(f"| {run_id} | {status} | {start} | {metrics_str} | {params_str} |")

    return "\n".join(lines)


@mcp.tool()
def get_run_details(run_id: str) -> str:
    """Full details of an MLflow run (parameters, metrics, tags, artifacts).

    Args:
        run_id: MLflow run ID.
    """
    client = _get_client()
    run = client.experiments.get_run(run_id=run_id)

    if not run.run:
        return f"Run '{run_id}' not found."

    info = run.run.info
    data = run.run.data

    lines = [f"## Run: {info.run_id}\n"]

    status = str(info.status) if info.status else "-"
    lines.append(f"**Status:** {status}")

    if info.start_time:
        start = datetime.fromtimestamp(
            info.start_time / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**Start:** {start}")

    if info.end_time:
        end = datetime.fromtimestamp(
            info.end_time / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**End:** {end}")

        if info.start_time:
            duration_s = (info.end_time - info.start_time) / 1000
            lines.append(f"**Duration:** {duration_s:.1f}s")

    if info.artifact_uri:
        lines.append(f"**Artifacts:** {info.artifact_uri}")

    if data and data.params:
        lines.append("\n### Parameters\n")
        lines.append("| Parameter | Value |")
        lines.append("| --- | --- |")
        for p in data.params:
            lines.append(f"| {p.key} | {p.value} |")

    if data and data.metrics:
        lines.append("\n### Metrics\n")
        lines.append("| Metric | Value |")
        lines.append("| --- | --- |")
        for m in data.metrics:
            lines.append(f"| {m.key} | {m.value} |")

    if data and data.tags:
        lines.append("\n### Tags\n")
        lines.append("| Tag | Value |")
        lines.append("| --- | --- |")
        for t in data.tags:
            if not t.key.startswith("mlflow."):
                lines.append(f"| {t.key} | {t.value} |")

    return "\n".join(lines)


@mcp.tool()
def compare_runs(run_ids: str) -> str:
    """Compare multiple MLflow runs side by side (metrics and parameters).

    Args:
        run_ids: Run IDs separated by commas (e.g., "run1,run2,run3").
    """
    client = _get_client()
    ids = [r.strip() for r in run_ids.split(",") if r.strip()]

    if len(ids) < 2:
        return "Please provide at least 2 run IDs separated by commas."

    runs_data = []
    for rid in ids:
        run = client.experiments.get_run(run_id=rid)
        if run.run:
            runs_data.append(run.run)

    if len(runs_data) < 2:
        return "Could not find at least 2 valid runs."

    all_metrics = set()
    all_params = set()
    for r in runs_data:
        if r.data and r.data.metrics:
            all_metrics.update(m.key for m in r.data.metrics)
        if r.data and r.data.params:
            all_params.update(p.key for p in r.data.params)

    run_labels = [r.info.run_id[:8] for r in runs_data]
    lines = []

    if all_metrics:
        lines.append("### Metrics\n")
        header = "| Metric | " + " | ".join(run_labels) + " |"
        sep = "| --- | " + " | ".join("---" for _ in run_labels) + " |"
        lines.append(header)
        lines.append(sep)

        for metric in sorted(all_metrics):
            values = []
            for r in runs_data:
                val = "-"
                if r.data and r.data.metrics:
                    for m in r.data.metrics:
                        if m.key == metric:
                            val = f"{m.value:.4g}"
                            break
                values.append(val)
            lines.append(f"| {metric} | " + " | ".join(values) + " |")

    if all_params:
        lines.append("\n### Parameters\n")
        header = "| Parameter | " + " | ".join(run_labels) + " |"
        sep = "| --- | " + " | ".join("---" for _ in run_labels) + " |"
        lines.append(header)
        lines.append(sep)

        for param in sorted(all_params):
            values = []
            for r in runs_data:
                val = "-"
                if r.data and r.data.params:
                    for p in r.data.params:
                        if p.key == param:
                            val = p.value
                            break
                values.append(val)
            lines.append(f"| {param} | " + " | ".join(values) + " |")

    return "\n".join(lines)


@mcp.tool()
def get_metric_history(run_id: str, metric_key: str) -> str:
    """History of a metric across training steps.

    Args:
        run_id: MLflow run ID.
        metric_key: Metric name (e.g., "loss", "accuracy").
    """
    client = _get_client()
    history = client.experiments.get_history(run_id=run_id, metric_key=metric_key)

    metrics = history.metrics if history.metrics else []
    if not metrics:
        return f"No history found for metric '{metric_key}' in run '{run_id}'."

    lines = [f"### History: {metric_key} (run {run_id[:8]})\n"]
    lines.append("| Step | Value | Timestamp |")
    lines.append("| --- | --- | --- |")

    for m in metrics:
        ts = "-"
        if m.timestamp:
            ts = datetime.fromtimestamp(
                m.timestamp / 1000, tz=timezone.utc
            ).strftime("%H:%M:%S")
        step = m.step if m.step is not None else "-"
        lines.append(f"| {step} | {m.value:.6g} | {ts} |")

    return "\n".join(lines)


@mcp.tool()
def list_registered_models(max_results: int = 20) -> str:
    """List registered models in Unity Catalog Model Registry.

    Args:
        max_results: Maximum number of models to return (default: 20).
    """
    client = _get_client()

    models = []
    for m in client.registered_models.list():
        models.append(m)
        if len(models) >= max_results:
            break

    if not models:
        return "No registered models found."

    lines = ["| Name | Description |", "| --- | --- |"]
    for m in models:
        desc = (m.description or "")[:80] if hasattr(m, "description") else ""
        name = m.name if hasattr(m, "name") else str(m)
        lines.append(f"| {name} | {desc} |")

    return "\n".join(lines)


@mcp.tool()
def get_model_versions(model_name: str) -> str:
    """List versions of a registered model in Unity Catalog.

    Args:
        model_name: Fully qualified model name (catalog.schema.model).
    """
    client = _get_client()

    versions = []
    for v in client.model_versions.list(full_name=model_name):
        versions.append(v)

    if not versions:
        return f"No versions found for model '{model_name}'."

    lines = ["| Version | Status | Created At | Description |",
             "| --- | --- | --- | --- |"]

    for v in versions:
        status = str(v.status) if hasattr(v, "status") and v.status else "-"
        created = "-"
        if hasattr(v, "creation_timestamp") and v.creation_timestamp:
            created = datetime.fromtimestamp(
                v.creation_timestamp / 1000, tz=timezone.utc
            ).strftime("%Y-%m-%d %H:%M")
        desc = (v.comment or "")[:60] if hasattr(v, "comment") else ""
        version = v.version if hasattr(v, "version") else "-"
        lines.append(f"| {version} | {status} | {created} | {desc} |")

    return "\n".join(lines)


@mcp.tool()
def list_serving_endpoints() -> str:
    """List model serving endpoints in the workspace."""
    client = _get_client()
    endpoints = list(client.serving_endpoints.list())

    if not endpoints:
        return "No serving endpoints found."

    lines = ["| Name | State | Created At |",
             "| --- | --- | --- |"]

    for ep in endpoints:
        state = "-"
        if ep.state and hasattr(ep.state, "ready"):
            state = str(ep.state.ready)
        created = "-"
        if ep.creation_timestamp:
            created = datetime.fromtimestamp(
                ep.creation_timestamp / 1000, tz=timezone.utc
            ).strftime("%Y-%m-%d %H:%M")
        lines.append(f"| {ep.name} | {state} | {created} |")

    return "\n".join(lines)


@mcp.tool()
def get_serving_endpoint(endpoint_name: str) -> str:
    """Details of a specific model serving endpoint.

    Args:
        endpoint_name: Serving endpoint name.
    """
    client = _get_client()
    ep = client.serving_endpoints.get(name=endpoint_name)

    lines = [f"## Endpoint: {ep.name}\n"]

    if ep.state:
        if hasattr(ep.state, "ready"):
            lines.append(f"**State:** {ep.state.ready}")
        if hasattr(ep.state, "config_update"):
            lines.append(f"**Config Update:** {ep.state.config_update}")

    if ep.creation_timestamp:
        created = datetime.fromtimestamp(
            ep.creation_timestamp / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**Created At:** {created}")

    if ep.last_updated_timestamp:
        updated = datetime.fromtimestamp(
            ep.last_updated_timestamp / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**Updated At:** {updated}")

    if ep.config and ep.config.served_entities:
        lines.append("\n### Served Models\n")
        lines.append("| Name | Version | Scale to Zero | Workload Size |")
        lines.append("| --- | --- | --- | --- |")
        for entity in ep.config.served_entities:
            name = entity.name or "-"
            version = entity.entity_version or "-"
            scale = str(entity.scale_to_zero_enabled) if hasattr(entity, "scale_to_zero_enabled") else "-"
            workload = str(entity.workload_size) if hasattr(entity, "workload_size") else "-"
            lines.append(f"| {name} | {version} | {scale} | {workload} |")

    if ep.config and ep.config.traffic_config and ep.config.traffic_config.routes:
        lines.append("\n### Traffic Routes\n")
        lines.append("| Model | Percentage |")
        lines.append("| --- | --- |")
        for route in ep.config.traffic_config.routes:
            lines.append(f"| {route.served_model_name} | {route.traffic_percentage}% |")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# ASGI Middleware — extracts Databricks credentials from HTTP headers
# ---------------------------------------------------------------------------

class _CredentialMiddleware:
    """ASGI middleware that populates contextvars from request headers."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            headers = dict(scope.get("headers", []))
            _db_host.set(headers.get(b"x-databricks-host", b"").decode())
            _db_token.set(headers.get(b"x-databricks-token", b"").decode())
            _db_warehouse_id.set(headers.get(b"x-databricks-warehouse-id", b"").decode())
        await self.app(scope, receive, send)


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

def create_app():
    """Create the ASGI app with credential middleware."""
    app = mcp.streamable_http_app()
    return _CredentialMiddleware(app)


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", "8787"))
    uvicorn.run(
        "databricks_mcp.server:create_app",
        factory=True,
        host="0.0.0.0",
        port=port,
    )
