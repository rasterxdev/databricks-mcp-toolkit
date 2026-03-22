# Databricks MCP Toolkit

**Conecte o Claude Code ao seu workspace Databricks e transforme linguagem natural em queries, análises e notebooks, sem sair do terminal.**

O Databricks MCP Toolkit é um pacote completo de integração entre o [Claude Code](https://docs.anthropic.com/en/docs/claude-code) e o Databricks. Ele inclui um MCP Server com 26 ferramentas, 3 agentes especializados e 15 skills prontos para uso imediato.

---

## Por que usar

- **Sem troca de contexto**: tudo acontece no terminal onde você já está
- **SQL via linguagem natural**: descreva o que precisa, o agente monta a query
- **Exploração guiada**: navegue pelo Unity Catalog de forma progressiva e estruturada
- **Notebooks prontos**: gere arquivos `.py` no formato Databricks com um comando
- **Segurança por padrão**: credenciais ficam locais, nunca são armazenadas no servidor

---

## Arquitetura

<p align="center">
  <img src="docs/architecture.svg" alt="Arquitetura do Databricks MCP Toolkit" width="100%">
</p>

[Ver detalhes da arquitetura →](docs/architecture.md)

---

## O que está incluso

### Agentes

Acionados automaticamente pelo Claude Code conforme o tipo de tarefa.

| Agente | Perfil | Quando é acionado |
|---|---|---|
| `databricks-analyst` | Analista de Dados sênior | Exploração de dados, SQL, notebooks PySpark |
| `databricks-scientist` | Cientista de Dados / ML Engineer | MLflow, modelos preditivos, séries temporais |
| `databricks-engineer` | Engenheiro de Dados / Arquiteto de Dados | Lakehouse, migração, governança, infra, ingestão, observabilidade |

[Ver detalhes dos agentes →](docs/agents.md)

### Skills — Slash Commands

| Comando | O que faz |
|---|---|
| `/sql` | Executar SQL ou gerar a partir de linguagem natural |
| `/analyze` | Análise exploratória completa (EDA) |
| `/notebook` | Criar notebook PySpark no formato Databricks |
| `/explore` | Navegar pelo Unity Catalog progressivamente |
| `/predict` | Pipeline ML completo (EDA → treino → MLflow) |
| `/stats` | Testes estatísticos avançados via SQL |
| `/timeseries` | Análise de séries temporais + forecasting |
| `/model` | Inspecionar experimentos, runs e endpoints MLflow |
| `/feature` | Análise de features e pipeline de engineering |
| `/governance` | Auditar governança de dados e permissões de acesso |
| `/infra` | Revisar infraestrutura e gerar recomendações de otimização |
| `/migrate` | Gerar plano de migração para Databricks |
| `/ingest` | Criar pipeline de ingestão de dados |
| `/observability` | Monitorar workspace via system tables |
| `/lakehouse` | Revisar arquitetura lakehouse e gerar plano de melhorias |

[Ver exemplos e detalhes →](docs/skills.md)

### Ferramentas MCP (26)

9 ferramentas de dados (SQL, Unity Catalog) + 9 de MLflow (experimentos, modelos, endpoints) + 8 de infraestrutura, governança e Delta Sharing. O Claude Code chama diretamente via protocolo MCP.

[Ver lista completa →](docs/tools.md)

---

## Instalação

### Pré-requisitos

1. [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado
2. Host do Databricks (ex: `https://dbc-xxx.cloud.databricks.com`)
3. Token de acesso pessoal (PAT) do Databricks
4. URL do servidor MCP
5. API Key do servidor MCP

### Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/rasterxtech/databricks-mcp-toolkit/main/setup.sh | bash
```

O instalador pede as informações acima e configura agentes, skills e conexão MCP globalmente. **Nenhuma instalação de Python necessária.**

---

## Atualização

Para atualizar agentes e skills, rode `/databricks-update` no Claude Code.

---

## Uso

Após a instalação, basta abrir qualquer terminal e rodar:

```bash
claude
```

Pronto. Agentes, skills e ferramentas funcionam em qualquer projeto, sem configuração adicional.

---

## Documentação

| Tópico | Link |
|---|---|
| Agentes | [docs/agents.md](docs/agents.md) |
| Skills (slash commands) | [docs/skills.md](docs/skills.md) |
| Ferramentas MCP | [docs/tools.md](docs/tools.md) |
| Arquitetura e estrutura | [docs/architecture.md](docs/architecture.md) |
| Customização | [docs/customization.md](docs/customization.md) |
| Contribuição e onboarding | [docs/contributing.md](docs/contributing.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |
