# Projeto Databricks - Data Team

## Ambiente

- Workspace: https://<seu-workspace>.cloud.databricks.com/
- MCP Server: instalado globalmente em `~/.local/share/databricks-mcp/`, configurado via `.mcp.json`
- Credenciais: carregadas do arquivo `.env` na raiz do projeto (`DATABRICKS_HOST` e `DATABRICKS_TOKEN`)
- Código-fonte do MCP: `databricks_mcp/server.py` (este repo é a source of truth)

## Ferramentas MCP disponíveis

Ao interagir com o Databricks, **sempre** use as ferramentas MCP (prefixo `mcp__databricks__`) ao invés de rodar scripts Python via Bash:

### Dados e SQL
- `run_sql` — executar queries SQL (retorna markdown formatado)
- `list_catalogs` / `list_schemas` / `list_tables` — navegar Unity Catalog
- `describe_table` — schema detalhado de uma tabela (colunas, tipos, comentários)
- `sample_table` — amostra rápida de dados
- `table_stats` — estatísticas básicas (contagem, nulos, distinct por coluna)
- `list_warehouses` — listar SQL Warehouses e seus estados
- `query_history` — histórico de queries recentes

### MLflow e Model Registry
- `list_experiments` — listar experimentos MLflow no workspace
- `get_experiment_runs` — listar runs de um experimento com métricas e parâmetros
- `get_run_details` — detalhes completos de um run (params, métricas, tags, artifacts)
- `compare_runs` — comparar múltiplos runs lado a lado (IDs separados por vírgula)
- `get_metric_history` — histórico de uma métrica ao longo dos steps de treinamento
- `list_registered_models` — listar modelos no Unity Catalog Model Registry
- `get_model_versions` — listar versões de um modelo registrado
- `list_serving_endpoints` — listar model serving endpoints
- `get_serving_endpoint` — detalhes de um serving endpoint específico

## Skills (slash commands)

### Análise de dados
- `/sql <query ou descrição>` — executar SQL ou gerar SQL a partir de linguagem natural
- `/analyze <catalog.schema.table>` — análise exploratória completa (EDA)
- `/notebook <descrição>` — criar notebook Python/PySpark no formato Databricks
- `/explore [catalog[.schema[.table]]]` — navegar Unity Catalog progressivamente

### Ciência de dados e ML
- `/predict <tabela e objetivo>` — criar notebook com pipeline ML completo (EDA → features → treino → avaliação → MLflow)
- `/stats <tabela ou descrição>` — executar testes estatísticos e análises avançadas via SQL
- `/timeseries <tabela ou descrição>` — análise de séries temporais + notebook de forecasting
- `/model <comando>` — inspecionar experimentos, runs, modelos e endpoints MLflow
- `/feature <tabela e target>` — análise de features e geração de pipeline de feature engineering

## Agents especializados

O agent `databricks-analyst` é acionado automaticamente para tarefas de análise de dados,
exploração de tabelas, escrita de SQL e criação de notebooks PySpark.

O agent `data-scientist` é acionado para tarefas de ciência de dados: ML lifecycle (MLflow),
análise estatística avançada, feature engineering, séries temporais e modelos preditivos.

## Convenções

- Formato de notebook Databricks: arquivos `.py` com `# Databricks notebook source` e `# COMMAND ----------`
- SQL: preferir CTEs sobre subqueries
- Sempre limitar resultados com LIMIT em queries exploratórias
- Nomes de tabelas no formato completo: `catalog.schema.table`
- Ao analisar uma tabela, seguir o fluxo: describe → stats → sample → queries específicas
