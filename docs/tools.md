# Ferramentas MCP

O MCP Server roda localmente e expõe 18 ferramentas que o Claude Code chama diretamente via o protocolo [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) por `stdio`. O servidor é iniciado automaticamente ao abrir o projeto, conforme configurado no `.mcp.json`.

---

## Dados e SQL

| Ferramenta | Descrição | Exemplo de uso |
|---|---|---|
| `run_sql` | Executa query SQL e retorna resultados formatados em markdown | `run_sql("SELECT * FROM silver.ibge.ipca_mensal LIMIT 10")` |
| `list_catalogs` | Lista todos os catálogos do Unity Catalog | Exploração inicial do workspace |
| `list_schemas` | Lista schemas de um catálogo | `list_schemas("silver")` |
| `list_tables` | Lista tabelas de um schema | `list_tables("silver", "ibge")` |
| `describe_table` | Retorna schema detalhado (colunas, tipos, comentários) | `describe_table("silver.ibge.ipca_mensal")` |
| `sample_table` | Amostra rápida de dados de uma tabela | `sample_table("silver.ibge.ipca_mensal", rows=10)` |
| `table_stats` | Estatísticas: contagem, nulos, cardinalidade por coluna | `table_stats("silver.ibge.ipca_mensal")` |
| `list_warehouses` | Lista SQL Warehouses e seus estados | Verificar warehouse disponível |
| `query_history` | Histórico de queries recentes no workspace | Auditoria e debug |

## MLflow e Model Registry

| Ferramenta | Descrição | Exemplo de uso |
|---|---|---|
| `list_experiments` | Lista experimentos MLflow no workspace | Descobrir experimentos disponíveis |
| `get_experiment_runs` | Lista runs de um experimento com métricas e parâmetros | `get_experiment_runs("123456")` |
| `get_run_details` | Detalhes completos de um run (params, métricas, tags, artifacts) | `get_run_details("run_id")` |
| `compare_runs` | Compara múltiplos runs lado a lado | `compare_runs("run1,run2,run3")` |
| `get_metric_history` | Histórico de uma métrica ao longo dos steps | `get_metric_history("run_id", "loss")` |
| `list_registered_models` | Lista modelos no Unity Catalog Model Registry | Descobrir modelos registrados |
| `get_model_versions` | Lista versões de um modelo registrado | `get_model_versions("catalog.schema.model")` |
| `list_serving_endpoints` | Lista model serving endpoints | Verificar endpoints ativos |
| `get_serving_endpoint` | Detalhes de um serving endpoint específico | `get_serving_endpoint("my-endpoint")` |

## Como funciona a conexão

O servidor carrega credenciais seguindo a prioridade: `.env` do projeto > `.databricks_mcp_cfg` global > perfil CLI. Seleciona automaticamente um SQL Warehouse em estado `RUNNING`. O client e o warehouse são cacheados para evitar reconexões desnecessárias. As ferramentas de MLflow e Model Registry usam o mesmo `WorkspaceClient` — sem dependências adicionais.
