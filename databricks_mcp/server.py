"""
MCP Server para Databricks.

Fornece ferramentas para executar SQL, explorar catálogos,
descrever tabelas e interagir com o workspace Databricks.

Uso:
    python databricks_mcp/server.py
"""

import os
from datetime import datetime, timezone
from functools import lru_cache
from textwrap import dedent

from dotenv import load_dotenv
from databricks.sdk import WorkspaceClient
from mcp.server.fastmcp import FastMCP

# Carrega .env da raiz do projeto (cwd do Claude Code)
load_dotenv()

# ── Inicialização ────────────────────────────────────────────────────────────

mcp = FastMCP(
    "Databricks",
    instructions=dedent("""
        Servidor MCP para interação com Databricks.
        Permite executar SQL, explorar catálogos/schemas/tabelas,
        e gerenciar recursos do workspace.
    """).strip(),
)


@lru_cache(maxsize=1)
def _get_client() -> WorkspaceClient:
    """Cria um WorkspaceClient (cacheado) usando variáveis de ambiente ou ~/.databrickscfg."""
    host = os.environ.get("DATABRICKS_HOST")
    token = os.environ.get("DATABRICKS_TOKEN")
    if host and token:
        return WorkspaceClient(host=host, token=token)
    # fallback para perfil do CLI
    return WorkspaceClient(profile="vscode_databricks")


@lru_cache(maxsize=1)
def _get_warehouse_id() -> str:
    """Retorna o warehouse_id configurado ou o primeiro disponível (cacheado)."""
    wh_id = os.environ.get("DATABRICKS_WAREHOUSE_ID")
    if wh_id:
        return wh_id
    client = _get_client()
    warehouses = list(client.warehouses.list())
    # prefere warehouse que já esteja RUNNING
    for wh in warehouses:
        if str(wh.state) == "State.RUNNING":
            return wh.id
    # senão, retorna o primeiro (será iniciado sob demanda)
    if warehouses:
        return warehouses[0].id
    raise RuntimeError("Nenhum SQL Warehouse encontrado no workspace.")


# ── Ferramentas ──────────────────────────────────────────────────────────────


@mcp.tool()
def run_sql(query: str, max_rows: int = 100) -> str:
    """Executa uma query SQL no Databricks e retorna os resultados.

    Args:
        query: Query SQL a ser executada.
        max_rows: Número máximo de linhas a retornar (padrão: 100).
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
        return f"ERRO: {status.error.message}"

    if not result.manifest or not result.manifest.schema:
        return "Query executada com sucesso (sem resultados)."

    columns = [col.name for col in result.manifest.schema.columns]
    rows = result.result.data_array if result.result and result.result.data_array else []

    # Formata como tabela markdown
    lines = []
    lines.append("| " + " | ".join(columns) + " |")
    lines.append("| " + " | ".join("---" for _ in columns) + " |")
    for row in rows:
        lines.append("| " + " | ".join(str(v) if v is not None else "NULL" for v in row) + " |")

    total = result.manifest.total_row_count
    if total and total > max_rows:
        lines.append(f"\n*Mostrando {max_rows} de {total} linhas. Use max_rows para ver mais.*")

    return "\n".join(lines)


@mcp.tool()
def list_catalogs() -> str:
    """Lista todos os catálogos disponíveis no Unity Catalog."""
    client = _get_client()
    catalogs = list(client.catalogs.list())
    if not catalogs:
        return "Nenhum catálogo encontrado."
    lines = ["| Catálogo | Tipo | Comentário |", "| --- | --- | --- |"]
    for cat in catalogs:
        comment = (cat.comment or "")[:80]
        cat_type = str(cat.catalog_type) if cat.catalog_type else "-"
        lines.append(f"| {cat.name} | {cat_type} | {comment} |")
    return "\n".join(lines)


@mcp.tool()
def list_schemas(catalog: str) -> str:
    """Lista todos os schemas de um catálogo.

    Args:
        catalog: Nome do catálogo.
    """
    client = _get_client()
    schemas = list(client.schemas.list(catalog_name=catalog))
    if not schemas:
        return f"Nenhum schema encontrado no catálogo '{catalog}'."
    lines = ["| Schema | Comentário |", "| --- | --- |"]
    for s in schemas:
        comment = (s.comment or "")[:80]
        lines.append(f"| {s.name} | {comment} |")
    return "\n".join(lines)


@mcp.tool()
def list_tables(catalog: str, schema: str) -> str:
    """Lista todas as tabelas de um schema.

    Args:
        catalog: Nome do catálogo.
        schema: Nome do schema.
    """
    client = _get_client()
    tables = list(client.tables.list(catalog_name=catalog, schema_name=schema))
    if not tables:
        return f"Nenhuma tabela encontrada em '{catalog}.{schema}'."
    lines = ["| Tabela | Tipo | Comentário |", "| --- | --- | --- |"]
    for t in tables:
        ttype = str(t.table_type).split(".")[-1] if t.table_type else "-"
        comment = (t.comment or "")[:80]
        lines.append(f"| {t.name} | {ttype} | {comment} |")
    return "\n".join(lines)


@mcp.tool()
def describe_table(full_table_name: str) -> str:
    """Retorna o schema detalhado de uma tabela (colunas, tipos, comentários).

    Args:
        full_table_name: Nome completo da tabela (catalog.schema.table).
    """
    client = _get_client()
    table = client.tables.get(full_name=full_table_name)

    lines = [f"## {table.full_name}\n"]

    if table.comment:
        lines.append(f"**Descrição:** {table.comment}\n")

    ttype = str(table.table_type).split(".")[-1] if table.table_type else "-"
    lines.append(f"**Tipo:** {ttype}")

    if table.storage_location:
        lines.append(f"**Storage:** {table.storage_location}")

    lines.append("")
    lines.append("| Coluna | Tipo | Nullable | Comentário |")
    lines.append("| --- | --- | --- | --- |")

    if table.columns:
        for col in table.columns:
            nullable = "Sim" if col.nullable else "Não"
            comment = (col.comment or "")[:60]
            lines.append(f"| {col.name} | {col.type_name} | {nullable} | {comment} |")

    return "\n".join(lines)


@mcp.tool()
def sample_table(full_table_name: str, rows: int = 10) -> str:
    """Retorna uma amostra de dados de uma tabela.

    Args:
        full_table_name: Nome completo da tabela (catalog.schema.table).
        rows: Número de linhas a retornar (padrão: 10).
    """
    query = f"SELECT * FROM `{full_table_name.replace('.', '`.`')}` LIMIT {rows}"
    return run_sql(query, max_rows=rows)


@mcp.tool()
def table_stats(full_table_name: str) -> str:
    """Retorna estatísticas básicas de uma tabela (contagem, nulos, distinct).

    Args:
        full_table_name: Nome completo da tabela (catalog.schema.table).
    """
    client = _get_client()
    table = client.tables.get(full_name=full_table_name)

    if not table.columns:
        return "Tabela sem colunas definidas."

    escaped = f"`{full_table_name.replace('.', '`.`')}`"

    # Conta total de linhas
    count_result = run_sql(f"SELECT COUNT(*) as total FROM {escaped}", max_rows=1)

    # Monta query de stats por coluna
    col_stats = []
    for col in table.columns[:20]:  # limita a 20 colunas para não estourar
        name = col.name
        col_stats.append(
            f"COUNT(DISTINCT `{name}`) as `{name}_distinct`, "
            f"SUM(CASE WHEN `{name}` IS NULL THEN 1 ELSE 0 END) as `{name}_nulls`"
        )

    stats_query = f"SELECT {', '.join(col_stats)} FROM {escaped}"
    stats_result = run_sql(stats_query, max_rows=1)

    return f"### Contagem\n{count_result}\n\n### Estatísticas por coluna\n{stats_result}"


@mcp.tool()
def list_warehouses() -> str:
    """Lista todos os SQL Warehouses disponíveis no workspace."""
    client = _get_client()
    warehouses = list(client.warehouses.list())
    if not warehouses:
        return "Nenhum SQL Warehouse encontrado."
    lines = ["| ID | Nome | Estado | Tipo |", "| --- | --- | --- | --- |"]
    for wh in warehouses:
        state = str(wh.state).split(".")[-1] if wh.state else "-"
        wh_type = str(wh.warehouse_type).split(".")[-1] if wh.warehouse_type else "-"
        lines.append(f"| {wh.id} | {wh.name} | {state} | {wh_type} |")
    return "\n".join(lines)


@mcp.tool()
def query_history(max_results: int = 10) -> str:
    """Lista as queries recentes executadas no workspace.

    Args:
        max_results: Número máximo de queries a retornar (padrão: 10).
    """
    client = _get_client()
    from databricks.sdk.service.sql import ListQueryHistoryRequest

    history = client.query_history.list(request=ListQueryHistoryRequest())

    lines = ["| Query ID | Status | Duração (ms) | Warehouse |", "| --- | --- | --- | --- |"]
    count = 0
    for q in history:
        if count >= max_results:
            break
        status = str(q.status).split(".")[-1] if q.status else "-"
        duration = q.execution_end_time_ms - q.query_start_time_ms if q.execution_end_time_ms and q.query_start_time_ms else "-"
        lines.append(f"| {q.query_id} | {status} | {duration} | {q.warehouse_id} |")
        count += 1

    return "\n".join(lines)


# ── MLflow & Model Registry ──────────────────────────────────────────────────


@mcp.tool()
def list_experiments(max_results: int = 20) -> str:
    """Lista experimentos MLflow no workspace.

    Args:
        max_results: Número máximo de experimentos a retornar (padrão: 20).
    """
    client = _get_client()
    experiments = list(client.experiments.list_experiments())

    if not experiments:
        return "Nenhum experimento encontrado."

    lines = ["| ID | Nome | Lifecycle |", "| --- | --- | --- |"]
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
    """Lista runs de um experimento MLflow com métricas e parâmetros.

    Args:
        experiment_id: ID do experimento MLflow.
        max_results: Número máximo de runs a retornar (padrão: 20).
    """
    client = _get_client()
    response = client.experiments.search_runs(
        experiment_ids=[experiment_id],
        max_results=max_results,
    )

    runs = response.runs if response.runs else []
    if not runs:
        return f"Nenhum run encontrado para o experimento '{experiment_id}'."

    lines = ["| Run ID | Status | Start Time | Métricas | Parâmetros |",
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
    """Detalhes completos de um run MLflow (parâmetros, métricas, tags, artifacts).

    Args:
        run_id: ID do run MLflow.
    """
    client = _get_client()
    run = client.experiments.get_run(run_id=run_id)

    if not run.run:
        return f"Run '{run_id}' não encontrado."

    info = run.run.info
    data = run.run.data

    lines = [f"## Run: {info.run_id}\n"]

    status = str(info.status) if info.status else "-"
    lines.append(f"**Status:** {status}")

    if info.start_time:
        start = datetime.fromtimestamp(
            info.start_time / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**Início:** {start}")

    if info.end_time:
        end = datetime.fromtimestamp(
            info.end_time / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**Fim:** {end}")

        if info.start_time:
            duration_s = (info.end_time - info.start_time) / 1000
            lines.append(f"**Duração:** {duration_s:.1f}s")

    if info.artifact_uri:
        lines.append(f"**Artifacts:** {info.artifact_uri}")

    # Parâmetros
    if data and data.params:
        lines.append("\n### Parâmetros\n")
        lines.append("| Parâmetro | Valor |")
        lines.append("| --- | --- |")
        for p in data.params:
            lines.append(f"| {p.key} | {p.value} |")

    # Métricas
    if data and data.metrics:
        lines.append("\n### Métricas\n")
        lines.append("| Métrica | Valor |")
        lines.append("| --- | --- |")
        for m in data.metrics:
            lines.append(f"| {m.key} | {m.value} |")

    # Tags
    if data and data.tags:
        lines.append("\n### Tags\n")
        lines.append("| Tag | Valor |")
        lines.append("| --- | --- |")
        for t in data.tags:
            if not t.key.startswith("mlflow."):
                lines.append(f"| {t.key} | {t.value} |")

    return "\n".join(lines)


@mcp.tool()
def compare_runs(run_ids: str) -> str:
    """Compara múltiplos runs MLflow lado a lado (métricas e parâmetros).

    Args:
        run_ids: IDs dos runs separados por vírgula (ex: "run1,run2,run3").
    """
    client = _get_client()
    ids = [r.strip() for r in run_ids.split(",") if r.strip()]

    if len(ids) < 2:
        return "Forneça pelo menos 2 run IDs separados por vírgula."

    runs_data = []
    for rid in ids:
        run = client.experiments.get_run(run_id=rid)
        if run.run:
            runs_data.append(run.run)

    if len(runs_data) < 2:
        return "Não foi possível encontrar pelo menos 2 runs válidos."

    # Coletar todas as métricas e parâmetros
    all_metrics = set()
    all_params = set()
    for r in runs_data:
        if r.data and r.data.metrics:
            all_metrics.update(m.key for m in r.data.metrics)
        if r.data and r.data.params:
            all_params.update(p.key for p in r.data.params)

    run_labels = [r.info.run_id[:8] for r in runs_data]
    lines = []

    # Tabela de métricas
    if all_metrics:
        lines.append("### Métricas\n")
        header = "| Métrica | " + " | ".join(run_labels) + " |"
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

    # Tabela de parâmetros
    if all_params:
        lines.append("\n### Parâmetros\n")
        header = "| Parâmetro | " + " | ".join(run_labels) + " |"
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
    """Histórico de uma métrica ao longo dos steps de treinamento.

    Args:
        run_id: ID do run MLflow.
        metric_key: Nome da métrica (ex: "loss", "accuracy").
    """
    client = _get_client()
    history = client.experiments.get_history(run_id=run_id, metric_key=metric_key)

    metrics = history.metrics if history.metrics else []
    if not metrics:
        return f"Nenhum histórico encontrado para a métrica '{metric_key}' no run '{run_id}'."

    lines = [f"### Histórico: {metric_key} (run {run_id[:8]})\n"]
    lines.append("| Step | Valor | Timestamp |")
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
    """Lista modelos registrados no Unity Catalog Model Registry.

    Args:
        max_results: Número máximo de modelos a retornar (padrão: 20).
    """
    client = _get_client()

    models = []
    for m in client.registered_models.list():
        models.append(m)
        if len(models) >= max_results:
            break

    if not models:
        return "Nenhum modelo registrado encontrado."

    lines = ["| Nome | Descrição |", "| --- | --- |"]
    for m in models:
        desc = (m.description or "")[:80] if hasattr(m, "description") else ""
        name = m.name if hasattr(m, "name") else str(m)
        lines.append(f"| {name} | {desc} |")

    return "\n".join(lines)


@mcp.tool()
def get_model_versions(model_name: str) -> str:
    """Lista versões de um modelo registrado no Unity Catalog.

    Args:
        model_name: Nome completo do modelo (catalog.schema.model).
    """
    client = _get_client()

    versions = []
    for v in client.model_versions.list(full_name=model_name):
        versions.append(v)

    if not versions:
        return f"Nenhuma versão encontrada para o modelo '{model_name}'."

    lines = ["| Versão | Status | Criado em | Descrição |",
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
    """Lista model serving endpoints do workspace."""
    client = _get_client()
    endpoints = list(client.serving_endpoints.list())

    if not endpoints:
        return "Nenhum serving endpoint encontrado."

    lines = ["| Nome | Estado | Criado em |",
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
    """Detalhes de um model serving endpoint específico.

    Args:
        endpoint_name: Nome do serving endpoint.
    """
    client = _get_client()
    ep = client.serving_endpoints.get(name=endpoint_name)

    lines = [f"## Endpoint: {ep.name}\n"]

    if ep.state:
        if hasattr(ep.state, "ready"):
            lines.append(f"**Estado:** {ep.state.ready}")
        if hasattr(ep.state, "config_update"):
            lines.append(f"**Config Update:** {ep.state.config_update}")

    if ep.creation_timestamp:
        created = datetime.fromtimestamp(
            ep.creation_timestamp / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**Criado em:** {created}")

    if ep.last_updated_timestamp:
        updated = datetime.fromtimestamp(
            ep.last_updated_timestamp / 1000, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"**Atualizado em:** {updated}")

    # Served models
    if ep.config and ep.config.served_entities:
        lines.append("\n### Modelos Servidos\n")
        lines.append("| Nome | Versão | Scale to Zero | Workload Size |")
        lines.append("| --- | --- | --- | --- |")
        for entity in ep.config.served_entities:
            name = entity.name or "-"
            version = entity.entity_version or "-"
            scale = str(entity.scale_to_zero_enabled) if hasattr(entity, "scale_to_zero_enabled") else "-"
            workload = str(entity.workload_size) if hasattr(entity, "workload_size") else "-"
            lines.append(f"| {name} | {version} | {scale} | {workload} |")

    if ep.config and ep.config.traffic_config and ep.config.traffic_config.routes:
        lines.append("\n### Rotas de Tráfego\n")
        lines.append("| Modelo | Percentual |")
        lines.append("| --- | --- |")
        for route in ep.config.traffic_config.routes:
            lines.append(f"| {route.served_model_name} | {route.traffic_percentage}% |")

    return "\n".join(lines)


# ── Entrypoint ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    mcp.run(transport="stdio")
