# Changelog

Todas as alterações relevantes deste projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.1] - 2026-03-13

### Correções

- fix: corrige perfil do databricks-analyst para Analista de Dados
- fix: corrige leitura de credenciais no curl | bash

### Outros

- Merge pull request #4 from rasterxdev/develop
- Merge pull request #3 from rasterxdev/develop

**Diff completo:** [v0.1.0...v0.1.1](https://github.com/rasterxdev/databricks-mcp-toolkit/compare/v0.1.0...v0.1.1)

Todas as alterações relevantes deste projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.0] - 2026-03-13

Release inicial do Databricks MCP Toolkit.

### Novidades

- MCP Server com 18 ferramentas para interação com Databricks (SQL, Unity Catalog, MLflow, Model Registry, Serving Endpoints)
- Agente **databricks-analyst** para exploração de dados, SQL e criação de notebooks PySpark
- Agente **data-scientist** para ML lifecycle, análise estatística, feature engineering e séries temporais
- 9 skills: `/sql`, `/analyze`, `/notebook`, `/explore`, `/predict`, `/stats`, `/timeseries`, `/model`, `/feature`
- Instalação remota via `curl | bash` (sem clonar o repositório)
- Instalação global ou por projeto com detecção automática de SQL Warehouse
- Sistema de auto-update com verificação em background e notificação na sessão
- Gerenciamento de credenciais com prioridade: `.env` do projeto > config global > perfil CLI

**Diff completo:** [v0.1.0](https://github.com/rasterxdev/databricks-mcp-toolkit/releases/tag/v0.1.0)
