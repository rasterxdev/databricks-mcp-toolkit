# Databricks MCP Toolkit

**Conecte o Claude Code ao seu workspace Databricks e transforme linguagem natural em queries, análises e notebooks, sem sair do terminal.**

O Databricks MCP Toolkit é um pacote completo de integração entre o [Claude Code](https://docs.anthropic.com/en/docs/claude-code) e o Databricks. Ele inclui um MCP Server com 18 ferramentas, 2 agentes especializados e 9 skills prontos para uso imediato.

---

## Por que usar

- **Sem troca de contexto**: tudo acontece no terminal onde você já está
- **SQL via linguagem natural**: descreva o que precisa, o agente monta a query
- **Exploração guiada**: navegue pelo Unity Catalog de forma progressiva e estruturada
- **Notebooks prontos**: gere arquivos `.py` no formato Databricks com um comando
- **Segurança por padrão**: credenciais ficam locais, nunca são armazenadas no servidor

---

## Arquitetura

```
┌──────────────────────────────────────┐
│  Computador do Usuário               │
│                                      │
│  Claude Code (com IA)                │
│    ├── agents/     (prompts locais)  │
│    ├── commands/   (skills locais)   │
│    └── .mcp.json   (URL + headers)   │
└──────────┬───────────────────────────┘
           │ HTTPS (tool calls + credenciais)
           ▼
┌──────────────────────────────────────┐
│  MCP Server       │
│                                      │
│  18 tools, sem IA, stateless         │
│  Recebe PAT do usuário por request   │
└──────────┬───────────────────────────┘
           │ HTTPS (Databricks SDK)
           ▼
┌──────────────────────────────────────┐
│  Databricks Workspace                │
│  SQL Warehouses, Unity Catalog,      │
│  MLflow, Model Serving               │
└──────────────────────────────────────┘
```

- **IA fica no computador do usuário** (Claude Code)
- **Server MCP é stateless** — apenas proxy entre Claude e Databricks
- **Credenciais são individuais** — cada usuário usa seu próprio PAT
- **Nenhuma instalação de Python** necessária no computador do usuário

---

## O que está incluso

### Agentes

Acionados automaticamente pelo Claude Code conforme o tipo de tarefa.

| Agente | Perfil | Quando é acionado |
|---|---|---|
| `databricks-analyst` | Analista de Dados sênior | Exploração de dados, SQL, notebooks PySpark |
| `data-scientist` | Cientista de Dados / ML Engineer | MLflow, modelos preditivos, séries temporais |

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

[Ver exemplos e detalhes →](docs/skills.md)

### Ferramentas MCP (18)

9 ferramentas de dados (SQL, Unity Catalog) + 9 de MLflow (experimentos, modelos, endpoints). O Claude Code chama diretamente via protocolo MCP.

[Ver lista completa →](docs/tools.md)

---

## Instalação (usuário)

### Pré-requisitos

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado
- Token de acesso pessoal (PAT) do Databricks
- URL do servidor MCP (fornecida pelo admin do time)

### Instalação rápida (recomendada)

```bash
curl -fsSL https://raw.githubusercontent.com/rasterxdev/databricks-mcp-toolkit/main/setup.sh | bash
```

O instalador pede a URL do servidor MCP e suas credenciais Databricks, depois configura tudo globalmente. **Nenhuma instalação de Python necessária.**

### Instalação a partir do clone

Para quem quer customizar ou contribuir:

```bash
git clone git@github.com:rasterxdev/databricks-mcp-toolkit.git && cd databricks-mcp-toolkit
./scripts/install.sh
```

---

## Deploy do Servidor MCP

O servidor precisa ser deployado uma única vez por time/organização.

### Fly.io (recomendado — gratuito)

```bash
# 1. Instalar Fly CLI: https://fly.io/docs/hands-on/install-flyctl/
# 2. Login
fly auth login

# 3. Deploy
fly launch --copy-config
fly deploy
```

O servidor roda em `https://<app-name>.fly.dev`. Passe essa URL para os usuários do time.

### Railway ($5/mês)

1. Conecte o repositório no [Railway](https://railway.app)
2. O Dockerfile será detectado automaticamente
3. O servidor roda na URL gerada pelo Railway

### Render (gratuito, com cold start)

1. Crie um novo **Web Service** no [Render](https://render.com)
2. Conecte o repositório e selecione **Docker**
3. O servidor roda na URL gerada pelo Render

> **Nota**: O Render dorme após 15min de inatividade. A primeira chamada pode levar ~30s.

---

## Atualização

Para atualizar agentes e skills locais, rode `/databricks-update` no Claude Code ou manualmente:

```bash
~/.local/share/databricks-mcp/update.sh
```

O servidor MCP é atualizado centralmente pelo admin (redeploy).

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
