# Changelog

Todas as alterações relevantes deste projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.5] - 2026-03-21

### Correções

- fix: usa `claude mcp add` nos instaladores e atualiza docs

### Outros

- Merge pull request #13 from rasterxdev/develop

**Diff completo:** [v0.1.4...v0.1.5](https://github.com/rasterxdev/databricks-mcp-toolkit/compare/v0.1.4...v0.1.5)

Todas as alterações relevantes deste projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.4] - 2026-03-21

### Correções

- fix: desabilita DNS rebinding protection para deploy em cloud

### Outros

- Merge pull request #11 from rasterxdev/develop

**Diff completo:** [v0.1.3...v0.1.4](https://github.com/rasterxdev/databricks-mcp-toolkit/compare/v0.1.3...v0.1.4)

Todas as alterações relevantes deste projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.3] - 2026-03-21

### Novidades

- feat: adiciona autenticação via API Key no MCP server

### Documentação

- docs: simplifica README para foco na instalação do usuário

### Outros

- Merge pull request #9 from rasterxdev/develop
- Merge pull request #8 from rasterxdev/develop

**Diff completo:** [v0.1.2...v0.1.3](https://github.com/rasterxdev/databricks-mcp-toolkit/compare/v0.1.2...v0.1.3)

Todas as alterações relevantes deste projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.2] - 2026-03-21

### Novidades

- feat: migra MCP server de stdio para HTTP (Streamable HTTP)

### Outros

- Merge pull request #6 from rasterxdev/develop

**Diff completo:** [v0.1.1...v0.1.2](https://github.com/rasterxdev/databricks-mcp-toolkit/compare/v0.1.1...v0.1.2)

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
