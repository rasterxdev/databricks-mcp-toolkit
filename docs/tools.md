# Ferramentas MCP

O MCP Server roda remotamente e expõe 26 ferramentas que o Claude Code chama diretamente via o protocolo [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) por HTTP. O servidor é stateless — recebe credenciais Databricks via headers em cada request.

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

## Infraestrutura, Governança e Delta Sharing

| Ferramenta | Descrição | Exemplo de uso |
|---|---|---|
| `list_jobs` | Lista todos os jobs (workflows) do workspace | Descobrir workflows configurados |
| `list_job_runs` | Lista execuções recentes de um job específico | `list_job_runs("123456")` |
| `list_clusters` | Lista todos os clusters de compute | Verificar clusters ativos e seus estados |
| `list_pipelines` | Lista pipelines DLT (Delta Live Tables) | Descobrir pipelines configurados |
| `get_grants` | Obtém grants (permissões diretas) de um objeto do Unity Catalog | `get_grants("catalog", "silver")` |
| `get_effective_grants` | Obtém grants efetivos (herdados + diretos) de um objeto | `get_effective_grants("table", "silver.ibge.ipca_mensal")` |
| `list_shares` | Lista shares do Delta Sharing | Descobrir dados compartilhados |
| `list_share_recipients` | Lista recipients do Delta Sharing | Verificar quem recebe dados compartilhados |

## Como funciona a conexão

O Claude Code envia credenciais Databricks como HTTP headers (`X-Databricks-Host`, `X-Databricks-Token`) em cada chamada de ferramenta. O server cria um `WorkspaceClient` com essas credenciais e seleciona automaticamente um SQL Warehouse em estado `RUNNING`. Clients e warehouses são cacheados por usuário para evitar reconexões desnecessárias. Uma `X-API-Key` protege o server contra acesso não autorizado.
