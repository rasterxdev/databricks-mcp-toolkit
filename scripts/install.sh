#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Databricks MCP Toolkit — Instalação Local (Client-Only)
#
# Para desenvolvedores que clonaram o repositório.
# Instala agentes, skills e configuração MCP globalmente.
#
# Uso:
#   git clone git@github.com:rasterxdev/databricks-mcp-toolkit.git
#   cd databricks-mcp-toolkit
#   ./scripts/install.sh
# ─────────────────────────────────────────────────────────────

set -e

MCP_HOME="$HOME/.local/share/databricks-mcp"
CLAUDE_GLOBAL="$HOME/.claude"
CFG_FILE="$MCP_HOME/.databricks_mcp_cfg"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── Cores ────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD="\033[1m"
    DIM="\033[2m"
    RESET="\033[0m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    CYAN="\033[36m"
    RED="\033[31m"
else
    BOLD="" DIM="" RESET="" GREEN="" YELLOW="" CYAN="" RED=""
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Databricks MCP Toolkit — Instalador Local v2${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${DIM}Origem:  $SCRIPT_DIR${RESET}"
echo -e "  ${DIM}Destino: $CLAUDE_GLOBAL/${RESET}"
echo ""
echo -e "  ${DIM}Instalação leve: apenas agentes, skills e configuração.${RESET}"
echo -e "  ${DIM}O MCP Server roda remotamente — sem Python local.${RESET}"
echo ""

# ── 1. Configuração do servidor MCP ─────────────────────────

echo -e "${BOLD}──────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  Servidor MCP${RESET}"
echo -e "${BOLD}──────────────────────────────────────────────────────────${RESET}"
echo ""

DEFAULT_SERVER_URL=""
if [ -f "$CFG_FILE" ]; then
    DEFAULT_SERVER_URL=$(grep "^MCP_SERVER_URL=" "$CFG_FILE" 2>/dev/null | cut -d= -f2-)
fi

echo "  URL do servidor MCP (onde o server está deployado)."
echo -e "  ${DIM}Ex: https://databricks-mcp.fly.dev${RESET}"
echo ""

if [ -n "$DEFAULT_SERVER_URL" ]; then
    read -r -p "  MCP_SERVER_URL [$DEFAULT_SERVER_URL]: " SERVER_URL
    SERVER_URL=${SERVER_URL:-$DEFAULT_SERVER_URL}
else
    read -r -p "  MCP_SERVER_URL: " SERVER_URL
fi

while [ -z "$SERVER_URL" ]; do
    echo -e "  ${RED}✗${RESET} URL do servidor é obrigatória."
    read -r -p "  MCP_SERVER_URL: " SERVER_URL
done

SERVER_URL="${SERVER_URL%/}"

echo ""

# ── 2. Credenciais Databricks ────────────────────────────────

echo -e "${BOLD}──────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  Credenciais Databricks${RESET}"
echo -e "${BOLD}──────────────────────────────────────────────────────────${RESET}"
echo ""

CONFIGURE_CREDS="s"

if [ -f "$CFG_FILE" ]; then
    EXISTING_HOST=$(grep "^DATABRICKS_HOST=" "$CFG_FILE" 2>/dev/null | cut -d= -f2-)
    if [ -n "$EXISTING_HOST" ]; then
        echo -e "  Credenciais existentes encontradas:"
        echo -e "  ${DIM}Host: $EXISTING_HOST${RESET}"
        echo ""
        read -r -p "  Deseja manter as credenciais atuais? [S/n] " KEEP_CREDS
        KEEP_CREDS=${KEEP_CREDS:-S}
        if [[ "$KEEP_CREDS" =~ ^[sS] ]]; then
            CONFIGURE_CREDS="n"
            echo -e "  ${GREEN}✓${RESET} Credenciais mantidas"
        fi
    fi
fi

if [ "$CONFIGURE_CREDS" = "s" ]; then
    echo "  Informe suas credenciais do Databricks."
    echo -e "  ${DIM}(Para gerar um token: Workspace > Settings > Developer > Access tokens)${RESET}"
    echo ""

    read -r -p "  DATABRICKS_HOST (ex: https://dbc-xxx.cloud.databricks.com): " DB_HOST
    while [ -z "$DB_HOST" ]; do
        echo -e "  ${RED}✗${RESET} DATABRICKS_HOST é obrigatório."
        read -r -p "  DATABRICKS_HOST: " DB_HOST
    done

    read -r -s -p "  DATABRICKS_TOKEN (input oculto): " DB_TOKEN
    echo ""
    while [ -z "$DB_TOKEN" ]; do
        echo -e "  ${RED}✗${RESET} DATABRICKS_TOKEN é obrigatório."
        read -r -s -p "  DATABRICKS_TOKEN: " DB_TOKEN
        echo ""
    done

    read -r -p "  DATABRICKS_WAREHOUSE_ID (opcional, Enter para auto-detectar): " DB_WAREHOUSE
fi

echo ""

# ── 3. Salvar configuração ───────────────────────────────────

echo -e "${BOLD}  Salvando configuração...${RESET}"
echo ""

mkdir -p "$MCP_HOME/commands" "$MCP_HOME/agents"

if [ "$CONFIGURE_CREDS" = "s" ]; then
    cat > "$CFG_FILE" << EOF
MCP_SERVER_URL=$SERVER_URL
DATABRICKS_HOST=$DB_HOST
DATABRICKS_TOKEN=$DB_TOKEN
EOF

    if [ -n "$DB_WAREHOUSE" ]; then
        echo "DATABRICKS_WAREHOUSE_ID=$DB_WAREHOUSE" >> "$CFG_FILE"
    fi

    chmod 600 "$CFG_FILE"
else
    if grep -q "^MCP_SERVER_URL=" "$CFG_FILE" 2>/dev/null; then
        sed -i "s|^MCP_SERVER_URL=.*|MCP_SERVER_URL=$SERVER_URL|" "$CFG_FILE"
    else
        echo "MCP_SERVER_URL=$SERVER_URL" >> "$CFG_FILE"
    fi

    DB_HOST=$(grep "^DATABRICKS_HOST=" "$CFG_FILE" | cut -d= -f2-)
    DB_TOKEN=$(grep "^DATABRICKS_TOKEN=" "$CFG_FILE" | cut -d= -f2-)
    DB_WAREHOUSE=$(grep "^DATABRICKS_WAREHOUSE_ID=" "$CFG_FILE" 2>/dev/null | cut -d= -f2- || true)
fi

echo -e "  ${GREEN}✓${RESET} Configuração salva em $CFG_FILE"

# ── 4. Copiar skills, agents e versão ────────────────────────

echo ""
echo -e "${BOLD}  Copiando agentes e skills do repositório...${RESET}"
echo ""

cp "$SCRIPT_DIR/.claude/commands/"*.md "$MCP_HOME/commands/" 2>/dev/null || true
cp "$SCRIPT_DIR/.claude/agents/"*.md "$MCP_HOME/agents/" 2>/dev/null || true
echo -e "  ${GREEN}✓${RESET} Skills e agentes copiados"

cp "$SCRIPT_DIR/VERSION" "$MCP_HOME/.version" 2>/dev/null || true
cp "$SCRIPT_DIR/update.sh" "$MCP_HOME/update.sh" 2>/dev/null || true
chmod +x "$MCP_HOME/update.sh" 2>/dev/null || true
echo -e "  ${GREEN}✓${RESET} Versionamento e auto-update"

echo ""

# ── 5. Instalar globalmente no ~/.claude/ ─────────────────────

echo -e "${BOLD}  Instalando globalmente em $CLAUDE_GLOBAL/ ...${RESET}"
echo ""

mkdir -p "$CLAUDE_GLOBAL/commands" "$CLAUDE_GLOBAL/agents"

cp "$MCP_HOME/commands/"*.md "$CLAUDE_GLOBAL/commands/" 2>/dev/null || true
cp "$MCP_HOME/agents/"*.md  "$CLAUDE_GLOBAL/agents/"   2>/dev/null || true
echo -e "  ${GREEN}✓${RESET} Agentes e skills instalados"

# CLAUDE.md global
CLAUDE_MD="$CLAUDE_GLOBAL/CLAUDE.md"
MARKER="# Databricks MCP Toolkit"

DATABRICKS_BLOCK=$(cat "$SCRIPT_DIR/docs/claude-md-template.md" 2>/dev/null || cat << 'CLAUDEMD_EOF'
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
- `/predict <tabela e objetivo>` — criar notebook com pipeline ML completo
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
)

if [ -f "$CLAUDE_MD" ]; then
    if grep -q "$MARKER" "$CLAUDE_MD"; then
        BEFORE=$(sed "/$MARKER/,\$d" "$CLAUDE_MD")
        if [ -n "$BEFORE" ]; then
            printf '%s\n\n%s\n' "$BEFORE" "$DATABRICKS_BLOCK" > "$CLAUDE_MD"
        else
            echo "$DATABRICKS_BLOCK" > "$CLAUDE_MD"
        fi
    else
        printf '\n\n%s\n' "$DATABRICKS_BLOCK" >> "$CLAUDE_MD"
    fi
else
    echo "$DATABRICKS_BLOCK" > "$CLAUDE_MD"
fi
echo -e "  ${GREEN}✓${RESET} CLAUDE.md instalado"

# ── 6. Gerar .mcp.json ──────────────────────────────────────

MCP_JSON="$CLAUDE_GLOBAL/.mcp.json"
MCP_URL="${SERVER_URL}/mcp"

HEADERS_JSON="{\"X-Databricks-Host\": \"${DB_HOST}\", \"X-Databricks-Token\": \"${DB_TOKEN}\""
if [ -n "$DB_WAREHOUSE" ]; then
    HEADERS_JSON="${HEADERS_JSON}, \"X-Databricks-Warehouse-Id\": \"${DB_WAREHOUSE}\""
fi
HEADERS_JSON="${HEADERS_JSON}}"

TMP_JSON=$(mktemp)

if [ -f "$MCP_JSON" ] && command -v python3 &>/dev/null; then
    python3 -c "
import json, sys

path = '$MCP_JSON'
try:
    with open(path) as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}

if 'mcpServers' not in data:
    data['mcpServers'] = {}

data['mcpServers']['databricks'] = {
    'url': '${MCP_URL}',
    'headers': json.loads('''${HEADERS_JSON}''')
}

with open('$TMP_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null || {
        cat > "$TMP_JSON" << MCPEOF
{
  "mcpServers": {
    "databricks": {
      "url": "${MCP_URL}",
      "headers": ${HEADERS_JSON}
    }
  }
}
MCPEOF
    }
else
    cat > "$TMP_JSON" << MCPEOF
{
  "mcpServers": {
    "databricks": {
      "url": "${MCP_URL}",
      "headers": ${HEADERS_JSON}
    }
  }
}
MCPEOF
fi

mv "$TMP_JSON" "$MCP_JSON"
chmod 600 "$MCP_JSON"
echo -e "  ${GREEN}✓${RESET} .mcp.json configurado (URL: $MCP_URL)"

# Salvar modo
echo "mode=global" > "$MCP_HOME/.install_mode"

# Gitignore global
GLOBAL_GITIGNORE="$HOME/.gitignore_global"
if [ ! -f "$GLOBAL_GITIGNORE" ] || ! grep -q "^\.mcp\.json$" "$GLOBAL_GITIGNORE" 2>/dev/null; then
    echo ".mcp.json" >> "$GLOBAL_GITIGNORE"
    git config --global core.excludesfile "$GLOBAL_GITIGNORE" 2>/dev/null || true
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Instalação completa!${RESET}"
echo ""
echo "  Abra qualquer terminal e rode:"
echo -e "    ${CYAN}claude${RESET}"
echo ""
echo "  O Databricks MCP já está disponível em qualquer projeto."
echo ""
echo -e "  ${DIM}Servidor: $SERVER_URL${RESET}"
echo -e "  ${DIM}Config:   $CFG_FILE${RESET}"
echo -e "  ${DIM}MCP:      $MCP_JSON${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
