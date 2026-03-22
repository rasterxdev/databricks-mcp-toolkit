# Arquitetura

O toolkit é composto por 3 camadas:

```
Computador do Usuário                MCP Server (cloud)           Databricks
┌──────────────────┐              ┌──────────────────┐       ┌──────────────┐
│ Claude Code (IA) │── HTTPS ──>  │ FastMCP (26 tools)│──>    │ Workspace    │
│ + agents/skills  │  headers     │ stateless, sem IA │ SDK   │ SQL, MLflow  │
└──────────────────┘              └──────────────────┘       └──────────────┘
```

- **IA** fica no computador do usuário (Claude Code)
- **MCP Server** roda na cloud (Render/Fly.io), stateless, sem IA
- **Credenciais** enviadas por request via HTTP headers (cada usuário usa seu PAT)
- **API Key** protege o server contra acesso não autorizado

---

## Estrutura no computador do usuário

```
~/.local/share/databricks-mcp/
├── .databricks_mcp_cfg           ← Config local (URL, API Key, credenciais)
├── .version                      ← Versão instalada
├── update.sh                     ← Auto-updater
├── commands/                     ← Templates das skills
│   ├── sql.md, analyze.md, notebook.md, explore.md
│   ├── predict.md, stats.md, timeseries.md
│   ├── model.md, feature.md
│   ├── governance.md, infra.md, migrate.md
│   ├── ingest.md, observability.md, lakehouse.md
└── agents/
    ├── databricks-analyst.md
    ├── databricks-scientist.md
    └── databricks-engineer.md

~/.claude/
├── CLAUDE.md                     ← Instruções globais para o Claude Code
├── commands/                     ← Skills disponíveis em qualquer projeto
│   ├── sql.md, analyze.md, ...
└── agents/
    ├── databricks-analyst.md
    ├── databricks-scientist.md
    └── databricks-engineer.md

~/.claude.json                    ← Config MCP (gerado por `claude mcp add`)
```

> A configuração MCP é registrada via `claude mcp add -t http -s user` e fica em `~/.claude.json`.
> Nenhuma instalação de Python necessária no computador do usuário.

---

## Repositório (source of truth)

```
databricks-mcp-toolkit/
├── databricks_mcp/
│   └── server.py                 ← MCP Server HTTP (deployado na cloud)
├── Dockerfile                    ← Build do container
├── requirements.txt              ← Dependências do server
├── render.yaml                   ← Config Render
├── fly.toml                      ← Config Fly.io
├── setup.sh                      ← Instalador remoto (curl | bash)
├── update.sh                     ← Auto-updater (baixado pelos instaladores)
├── VERSION                       ← Versão atual
├── CHANGELOG.md                  ← Histórico de releases
├── CLAUDE.md                     ← Instruções para agentes (este repo)
├── README.md                     ← Documentação principal
├── .claude/
│   ├── commands/*.md             ← 16 skills
│   └── agents/*.md               ← 3 agentes
├── scripts/
│   ├── install.sh                ← Instalador via clone
│   ├── release.sh                ← Automação de release
│   └── post-release.sh           ← Publicação de release
└── docs/                         ← Documentação detalhada
```
