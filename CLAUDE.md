# Projeto Databricks - Data Team

## Ambiente

- Workspace: https://<seu-workspace>.cloud.databricks.com/
- MCP Server: roda remotamente (HTTP), configurado via `~/.claude/.mcp.json`
- Credenciais: cada usuário configura seu PAT localmente no `.mcp.json` (headers HTTP)
  - Config local: `~/.local/share/databricks-mcp/.databricks_mcp_cfg` (criado pelo instalador)
  - Credenciais são enviadas como headers HTTP em cada request MCP
- Código-fonte do MCP Server: `databricks_mcp/server.py` (este repo é a source of truth)
- Deploy: Dockerfile na raiz, compatível com Fly.io, Railway, Render

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

## Convenções de dados

- Formato de notebook Databricks: arquivos `.py` com `# Databricks notebook source` e `# COMMAND ----------`
- SQL: preferir CTEs sobre subqueries
- Sempre limitar resultados com LIMIT em queries exploratórias
- Nomes de tabelas no formato completo: `catalog.schema.table`
- Ao analisar uma tabela, seguir o fluxo: describe → stats → sample → queries específicas

## Convenções de desenvolvimento

### Commits

Seguir [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — nova funcionalidade
- `fix:` — correção de bug
- `docs:` — documentação
- `release: vX.Y.Z` — commit de release (gerado pelo script)

Mensagens em português, concisas (1-2 frases), focando no "porquê" e não no "o quê".
Sempre incluir `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` quando o agente contribuir.

### Branches

- `main` — **protegida**, só recebe merges via PR. Nunca commitar direto.
- `develop` — branch de desenvolvimento. Todo trabalho acontece aqui.
- `feat/<nome>` — branches de feature, criados a partir de `develop` (opcional, para features grandes)
- `release/vX.Y.Z` — branch temporário de release (criado pelo `scripts/release.sh`, removido pelo `scripts/post-release.sh`)

### Fluxo de trabalho

1. **Desenvolver:** sempre criar ou usar a branch `develop`. Nunca trabalhar direto na `main`.
   ```
   git checkout develop  # ou: git checkout -b develop (se não existir)
   ```
2. **Commitar:** fazer commits na `develop` seguindo Conventional Commits.
3. **Subir PR:** quando pronto, fazer push da `develop` e abrir PR para `main`.
   ```
   git push -u origin develop
   gh pr create --base main --head develop --title "descrição"
   ```
4. **Revisar e mergear:** merge do PR no GitHub.
5. **Release:** após o merge na main, seguir o fluxo de release abaixo.

### Releases

O projeto usa Versionamento Semântico (`MAJOR.MINOR.PATCH`). O fluxo é automatizado:

1. **Preparar:** checkout na `main` atualizada, rodar `./scripts/release.sh patch|minor|major`
2. **Revisar:** merge do PR de release no GitHub
3. **Publicar:** `./scripts/post-release.sh vX.Y.Z` — push da tag, cria GitHub Release, limpa branch

**Nunca** fazer bump manual do `VERSION` ou editar `CHANGELOG.md` diretamente — sempre usar os scripts.
**Nunca** commitar direto na `main` — sempre via PR.

### Estrutura do repositório

```
databricks_mcp/server.py        — MCP Server HTTP (deployado na cloud)
Dockerfile, requirements.txt    — deployment do server
fly.toml                        — config Fly.io (deploy gratuito)
setup.sh, update.sh, VERSION    — raiz (URLs públicas, não mover)
scripts/install.sh              — instalador via clone (contribuidores)
scripts/release.sh              — automação de release (dev-only)
scripts/post-release.sh         — publicação de release (dev-only)
.claude/commands/*.md            — skills (slash commands)
.claude/agents/*.md              — agentes especializados
```
