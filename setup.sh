#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Databricks MCP Toolkit — Instalação Remota
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/rasterxdev/databricks-mcp-toolkit/main/setup.sh | bash
#
# Instala o MCP Server, agentes e skills globalmente para
# uso imediato com o Claude Code — sem clonar o repositório.
# ─────────────────────────────────────────────────────────────

set -e

REPO_RAW="https://raw.githubusercontent.com/rasterxdev/databricks-mcp-toolkit/main"
MCP_HOME="$HOME/.local/share/databricks-mcp"
CLAUDE_GLOBAL="$HOME/.claude"
CFG_FILE="$MCP_HOME/.databricks_mcp_cfg"

# ── Cores (desliga se não for terminal) ──────────────────────
if [ -t 1 ]; then
    BOLD="\033[1m"
    DIM="\033[2m"
    RESET="\033[0m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    CYAN="\033[36m"
else
    BOLD="" DIM="" RESET="" GREEN="" YELLOW="" CYAN=""
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Databricks MCP Toolkit — Instalador${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${DIM}Destino: $MCP_HOME${RESET}"
echo ""

# ── 0. Checar pré-requisitos ────────────────────────────────

check_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo "  ❌ $1 não encontrado. Instale antes de continuar."
        exit 1
    fi
}

check_cmd python3
check_cmd curl
check_cmd git

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 10 ]; }; then
    echo "  ❌ Python 3.10+ é necessário (encontrado: $PYTHON_VERSION)"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} Python $PYTHON_VERSION"

# Checar se o módulo venv está disponível (no Ubuntu/Debian precisa de python3.X-venv)
if ! python3 -c "import venv" &>/dev/null; then
    echo -e "  ${YELLOW}❌${RESET} Módulo ${BOLD}venv${RESET} não encontrado."
    echo ""
    echo -e "  No Ubuntu/Debian, instale com:"
    echo -e "    ${CYAN}sudo apt install python${PYTHON_VERSION}-venv${RESET}"
    echo ""
    echo -e "  No Fedora/RHEL:"
    echo -e "    ${CYAN}sudo dnf install python3-libs${RESET}"
    echo ""
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} Python venv"

if command -v claude &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} Claude Code encontrado"
else
    echo -e "  ${YELLOW}⚠${RESET}  Claude Code não encontrado — instale depois: ${DIM}npm install -g @anthropic-ai/claude-code${RESET}"
fi

echo ""

# ── 1. Baixar arquivos do GitHub ─────────────────────────────

echo -e "${BOLD}  📥 Baixando arquivos...${RESET}"
echo ""

mkdir -p "$MCP_HOME/commands" "$MCP_HOME/agents"

# Server
curl -fsSL "$REPO_RAW/databricks_mcp/server.py" -o "$MCP_HOME/server.py"
echo -e "  ${GREEN}✓${RESET} MCP Server"

# Skills
SKILLS="sql analyze notebook explore predict stats timeseries model feature"
for skill in $SKILLS; do
    curl -fsSL "$REPO_RAW/.claude/commands/${skill}.md" -o "$MCP_HOME/commands/${skill}.md"
done
echo -e "  ${GREEN}✓${RESET} Skills ($( echo "$SKILLS" | wc -w | tr -d ' '))"

# Agents
AGENTS="databricks-analyst data-scientist"
for agent in $AGENTS; do
    curl -fsSL "$REPO_RAW/.claude/agents/${agent}.md" -o "$MCP_HOME/agents/${agent}.md"
done
echo -e "  ${GREEN}✓${RESET} Agentes ($( echo "$AGENTS" | wc -w | tr -d ' '))"

# Versão e atualizador
curl -fsSL "$REPO_RAW/VERSION" -o "$MCP_HOME/.version"
curl -fsSL "$REPO_RAW/update.sh" -o "$MCP_HOME/update.sh"
chmod +x "$MCP_HOME/update.sh"
curl -fsSL "$REPO_RAW/.claude/commands/databricks-update.md" -o "$MCP_HOME/commands/databricks-update.md"
echo -e "  ${GREEN}✓${RESET} Versionamento e auto-update"

echo ""

# ── 2. Criar/atualizar ambiente virtual ──────────────────────

if [ ! -d "$MCP_HOME/.venv" ]; then
    echo -e "${BOLD}  📦 Criando ambiente virtual...${RESET}"
    python3 -m venv "$MCP_HOME/.venv"
    "$MCP_HOME/.venv/bin/pip" install --quiet databricks-connect databricks-sdk "mcp[cli]" python-dotenv
    echo -e "  ${GREEN}✓${RESET} Ambiente virtual criado e dependências instaladas"
else
    echo -e "  ${DIM}Atualizando dependências...${RESET}"
    "$MCP_HOME/.venv/bin/pip" install --quiet --upgrade databricks-connect databricks-sdk "mcp[cli]" python-dotenv
    echo -e "  ${GREEN}✓${RESET} Dependências atualizadas"
fi

echo ""

# ── 3. Credenciais ───────────────────────────────────────────

echo -e "${BOLD}──────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  Credenciais Databricks${RESET}"
echo -e "${BOLD}──────────────────────────────────────────────────────────${RESET}"
echo ""

CONFIGURE_CREDS="s"

if [ -f "$CFG_FILE" ]; then
    echo -e "  Credenciais existentes encontradas em:"
    echo -e "  ${DIM}$CFG_FILE${RESET}"
    echo ""
    read -r -p "  Deseja manter as credenciais atuais? [S/n] " KEEP_CREDS < /dev/tty
    KEEP_CREDS=${KEEP_CREDS:-S}
    if [[ "$KEEP_CREDS" =~ ^[sS] ]]; then
        CONFIGURE_CREDS="n"
        echo -e "  ${GREEN}✓${RESET} Credenciais mantidas"
    fi
fi

if [ "$CONFIGURE_CREDS" = "s" ]; then
    echo ""
    echo "  Informe suas credenciais do Databricks."
    echo -e "  ${DIM}(Para gerar um token: Workspace → Settings → Developer → Access tokens)${RESET}"
    echo ""

    read -r -p "  DATABRICKS_HOST (ex: https://dbc-xxx.cloud.databricks.com): " DB_HOST < /dev/tty
    while [ -z "$DB_HOST" ]; do
        echo "  ❌ DATABRICKS_HOST é obrigatório."
        read -r -p "  DATABRICKS_HOST: " DB_HOST < /dev/tty
    done

    read -r -s -p "  DATABRICKS_TOKEN (input oculto): " DB_TOKEN < /dev/tty
    echo ""
    while [ -z "$DB_TOKEN" ]; do
        echo "  ❌ DATABRICKS_TOKEN é obrigatório."
        read -r -s -p "  DATABRICKS_TOKEN: " DB_TOKEN < /dev/tty
        echo ""
    done

    read -r -p "  DATABRICKS_WAREHOUSE_ID (opcional, Enter para auto-detectar): " DB_WAREHOUSE < /dev/tty

    cat > "$CFG_FILE" << EOF
DATABRICKS_HOST=$DB_HOST
DATABRICKS_TOKEN=$DB_TOKEN
EOF

    if [ -n "$DB_WAREHOUSE" ]; then
        echo "DATABRICKS_WAREHOUSE_ID=$DB_WAREHOUSE" >> "$CFG_FILE"
    fi

    chmod 600 "$CFG_FILE"
    echo ""
    echo -e "  ${GREEN}✓${RESET} Credenciais salvas em $CFG_FILE"
fi

echo ""

# ── 4. Instalação global no ~/.claude/ ───────────────────────

echo -e "${BOLD}  📦 Instalando globalmente em $CLAUDE_GLOBAL/ ...${RESET}"
echo ""

mkdir -p "$CLAUDE_GLOBAL/commands" "$CLAUDE_GLOBAL/agents"

# Copiar skills e agents
cp "$MCP_HOME/commands/"*.md "$CLAUDE_GLOBAL/commands/" 2>/dev/null || true
cp "$MCP_HOME/agents/"*.md  "$CLAUDE_GLOBAL/agents/"   2>/dev/null || true
echo -e "  ${GREEN}✓${RESET} Agentes e skills instalados"

# CLAUDE.md global
cat > "$CLAUDE_GLOBAL/CLAUDE.md" << 'CLAUDEMD_EOF'
# Databricks MCP Toolkit

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
CLAUDEMD_EOF
echo -e "  ${GREEN}✓${RESET} CLAUDE.md instalado"

# .mcp.json global (merge seguro)
"$MCP_HOME/.venv/bin/python" << PYEOF
import json, os

mcp_json_path = os.path.expanduser("$CLAUDE_GLOBAL/.mcp.json")
server_cmd = os.path.expanduser("$MCP_HOME/.venv/bin/python")
server_arg = os.path.expanduser("$MCP_HOME/server.py")

data = {}
if os.path.isfile(mcp_json_path):
    with open(mcp_json_path) as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            data = {}

if "mcpServers" not in data:
    data["mcpServers"] = {}

data["mcpServers"]["databricks"] = {
    "command": server_cmd,
    "args": [server_arg]
}

with open(mcp_json_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
echo -e "  ${GREEN}✓${RESET} .mcp.json configurado"

# Salvar modo
echo "mode=global" > "$MCP_HOME/.install_mode"

# Gitignore global
GLOBAL_GITIGNORE="$HOME/.gitignore_global"
if [ ! -f "$GLOBAL_GITIGNORE" ] || ! grep -q "^\.mcp\.json$" "$GLOBAL_GITIGNORE"; then
    echo ".mcp.json" >> "$GLOBAL_GITIGNORE"
    git config --global core.excludesfile "$GLOBAL_GITIGNORE"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  ✅ Instalação completa!${RESET}"
echo ""
echo "  Abra qualquer terminal e rode:"
echo -e "    ${CYAN}claude${RESET}"
echo ""
echo "  O Databricks MCP já está disponível em qualquer projeto."
echo ""
echo "  Credenciais: $CFG_FILE"
echo "  Para override por projeto, crie um .env local com"
echo "  DATABRICKS_HOST e DATABRICKS_TOKEN."
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
