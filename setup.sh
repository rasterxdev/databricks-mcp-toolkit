#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Databricks MCP Toolkit — Instalação Remota (Client-Only)
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/rasterxdev/databricks-mcp-toolkit/main/setup.sh | bash
#
# Instala agentes, skills e configuração MCP globalmente para
# uso imediato com o Claude Code — sem clonar o repositório.
#
# O MCP Server roda remotamente (ex: Fly.io, Railway, Render).
# Nenhuma instalação de Python ou dependências é necessária.
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
    RED="\033[31m"
else
    BOLD="" DIM="" RESET="" GREEN="" YELLOW="" CYAN="" RED=""
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Databricks MCP Toolkit — Instalador v2${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${DIM}Instalação leve: apenas agentes, skills e configuração.${RESET}"
echo -e "  ${DIM}O MCP Server roda remotamente — sem Python local.${RESET}"
echo ""

# ── 0. Checar pré-requisitos ────────────────────────────────

check_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "  ${RED}✗${RESET} $1 não encontrado. Instale antes de continuar."
        exit 1
    fi
}

check_cmd curl

if command -v claude &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} Claude Code encontrado"
else
    echo -e "  ${YELLOW}!${RESET} Claude Code não encontrado — instale depois: ${DIM}npm install -g @anthropic-ai/claude-code${RESET}"
fi

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
    read -r -p "  MCP_SERVER_URL [$DEFAULT_SERVER_URL]: " SERVER_URL < /dev/tty
    SERVER_URL=${SERVER_URL:-$DEFAULT_SERVER_URL}
else
    read -r -p "  MCP_SERVER_URL: " SERVER_URL < /dev/tty
fi

while [ -z "$SERVER_URL" ]; do
    echo -e "  ${RED}✗${RESET} URL do servidor é obrigatória."
    read -r -p "  MCP_SERVER_URL: " SERVER_URL < /dev/tty
done

# Remover trailing slash
SERVER_URL="${SERVER_URL%/}"

# API Key do servidor
DEFAULT_API_KEY=""
if [ -f "$CFG_FILE" ]; then
    DEFAULT_API_KEY=$(grep "^MCP_API_KEY=" "$CFG_FILE" 2>/dev/null | cut -d= -f2-)
fi

echo ""
echo "  Chave de acesso do servidor (API Key)."
echo -e "  ${DIM}Fornecida pelo admin do time. Protege contra uso não autorizado.${RESET}"
echo ""

if [ -n "$DEFAULT_API_KEY" ]; then
    read -r -s -p "  MCP_API_KEY [manter atual]: " API_KEY < /dev/tty
    echo ""
    API_KEY=${API_KEY:-$DEFAULT_API_KEY}
else
    read -r -s -p "  MCP_API_KEY: " API_KEY < /dev/tty
    echo ""
fi

while [ -z "$API_KEY" ]; do
    echo -e "  ${RED}✗${RESET} API Key é obrigatória."
    read -r -s -p "  MCP_API_KEY: " API_KEY < /dev/tty
    echo ""
done

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
        read -r -p "  Deseja manter as credenciais atuais? [S/n] " KEEP_CREDS < /dev/tty
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

    read -r -p "  DATABRICKS_HOST (ex: https://dbc-xxx.cloud.databricks.com): " DB_HOST < /dev/tty
    while [ -z "$DB_HOST" ]; do
        echo -e "  ${RED}✗${RESET} DATABRICKS_HOST é obrigatório."
        read -r -p "  DATABRICKS_HOST: " DB_HOST < /dev/tty
    done

    read -r -s -p "  DATABRICKS_TOKEN (input oculto): " DB_TOKEN < /dev/tty
    echo ""
    while [ -z "$DB_TOKEN" ]; do
        echo -e "  ${RED}✗${RESET} DATABRICKS_TOKEN é obrigatório."
        read -r -s -p "  DATABRICKS_TOKEN: " DB_TOKEN < /dev/tty
        echo ""
    done

    read -r -p "  DATABRICKS_WAREHOUSE_ID (opcional, Enter para auto-detectar): " DB_WAREHOUSE < /dev/tty
fi

echo ""

# ── 3. Salvar configuração ───────────────────────────────────

echo -e "${BOLD}  Salvando configuração...${RESET}"
echo ""

mkdir -p "$MCP_HOME/commands" "$MCP_HOME/agents"

if [ "$CONFIGURE_CREDS" = "s" ]; then
    cat > "$CFG_FILE" << EOF
MCP_SERVER_URL=$SERVER_URL
MCP_API_KEY=$API_KEY
DATABRICKS_HOST=$DB_HOST
DATABRICKS_TOKEN=$DB_TOKEN
EOF

    if [ -n "$DB_WAREHOUSE" ]; then
        echo "DATABRICKS_WAREHOUSE_ID=$DB_WAREHOUSE" >> "$CFG_FILE"
    fi

    chmod 600 "$CFG_FILE"
else
    # Atualizar URL e API Key sem recriar o config
    if grep -q "^MCP_SERVER_URL=" "$CFG_FILE" 2>/dev/null; then
        sed -i "s|^MCP_SERVER_URL=.*|MCP_SERVER_URL=$SERVER_URL|" "$CFG_FILE"
    else
        echo "MCP_SERVER_URL=$SERVER_URL" >> "$CFG_FILE"
    fi

    if grep -q "^MCP_API_KEY=" "$CFG_FILE" 2>/dev/null; then
        sed -i "s|^MCP_API_KEY=.*|MCP_API_KEY=$API_KEY|" "$CFG_FILE"
    else
        echo "MCP_API_KEY=$API_KEY" >> "$CFG_FILE"
    fi

    # Ler credenciais existentes para uso no .mcp.json
    DB_HOST=$(grep "^DATABRICKS_HOST=" "$CFG_FILE" | cut -d= -f2-)
    DB_TOKEN=$(grep "^DATABRICKS_TOKEN=" "$CFG_FILE" | cut -d= -f2-)
    DB_WAREHOUSE=$(grep "^DATABRICKS_WAREHOUSE_ID=" "$CFG_FILE" 2>/dev/null | cut -d= -f2- || true)
fi

echo -e "  ${GREEN}✓${RESET} Configuração salva em $CFG_FILE"

# ── 4. Baixar skills, agents e versão ────────────────────────

echo ""
echo -e "${BOLD}  Baixando agentes e skills...${RESET}"
echo ""

# Skills
SKILLS="sql analyze notebook explore predict stats timeseries model feature governance infra migrate ingest observability lakehouse databricks-update"
for skill in $SKILLS; do
    curl -fsSL "$REPO_RAW/.claude/commands/${skill}.md" -o "$MCP_HOME/commands/${skill}.md"
done
echo -e "  ${GREEN}✓${RESET} Skills ($(echo "$SKILLS" | wc -w | tr -d ' '))"

# Agents
AGENTS="databricks-analyst databricks-scientist databricks-engineer"
for agent in $AGENTS; do
    curl -fsSL "$REPO_RAW/.claude/agents/${agent}.md" -o "$MCP_HOME/agents/${agent}.md"
done
echo -e "  ${GREEN}✓${RESET} Agentes ($(echo "$AGENTS" | wc -w | tr -d ' '))"

# Versão e atualizador
curl -fsSL "$REPO_RAW/VERSION" -o "$MCP_HOME/.version"
curl -fsSL "$REPO_RAW/update.sh" -o "$MCP_HOME/update.sh"
chmod +x "$MCP_HOME/update.sh"
echo -e "  ${GREEN}✓${RESET} Versionamento e auto-update"

echo ""

# ── 5. Instalar globalmente no ~/.claude/ ─────────────────────

echo -e "${BOLD}  Instalando globalmente em $CLAUDE_GLOBAL/ ...${RESET}"
echo ""

mkdir -p "$CLAUDE_GLOBAL/commands" "$CLAUDE_GLOBAL/agents"

# Copiar skills e agents
cp "$MCP_HOME/commands/"*.md "$CLAUDE_GLOBAL/commands/" 2>/dev/null || true
cp "$MCP_HOME/agents/"*.md  "$CLAUDE_GLOBAL/agents/"   2>/dev/null || true
echo -e "  ${GREEN}✓${RESET} Agentes e skills instalados"

# CLAUDE.md global (preservar existente se tiver conteúdo extra)
CLAUDE_MD="$CLAUDE_GLOBAL/CLAUDE.md"
MARKER="# Databricks MCP Toolkit"

# Gerar conteúdo do bloco Databricks
DATABRICKS_BLOCK=$(cat << 'CLAUDEMD_EOF'
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

### Infraestrutura, Governança e Delta Sharing
- `list_jobs` — listar todos os jobs (workflows) do workspace
- `list_job_runs` — listar execuções recentes de um job específico
- `list_clusters` — listar todos os clusters de compute
- `list_pipelines` — listar pipelines DLT (Delta Live Tables)
- `get_grants` — obter grants (permissões diretas) de um objeto do Unity Catalog
- `get_effective_grants` — obter grants efetivos (herdados + diretos) de um objeto
- `list_shares` — listar shares do Delta Sharing
- `list_share_recipients` — listar recipients do Delta Sharing

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

### Engenharia de dados e arquitetura
- `/governance [catalog[.schema[.table]]]` — auditar governança de dados e permissões de acesso
- `/infra` — revisar infraestrutura e gerar recomendações de otimização
- `/migrate <plataforma e descrição>` — gerar plano de migração de outra plataforma para Databricks
- `/ingest <fonte e destino>` — criar notebook de pipeline de ingestão de dados
- `/observability` — monitorar workspace via system tables
- `/lakehouse` — revisar arquitetura lakehouse e gerar plano de melhorias

## Agents especializados

O agent `databricks-analyst` é acionado automaticamente para tarefas de análise de dados,
exploração de tabelas, escrita de SQL e criação de notebooks PySpark.

O agent `databricks-scientist` é acionado para tarefas de ciência de dados: ML lifecycle (MLflow),
análise estatística avançada, feature engineering, séries temporais e modelos preditivos.

O agent `databricks-engineer` é acionado para tarefas de engenharia de dados e arquitetura:
lakehouse design, migração, governança, infraestrutura, ingestão e observabilidade.

## Convenções

- Formato de notebook Databricks: arquivos `.py` com `# Databricks notebook source` e `# COMMAND ----------`
- SQL: preferir CTEs sobre subqueries
- Sempre limitar resultados com LIMIT em queries exploratórias
- Nomes de tabelas no formato completo: `catalog.schema.table`
- Ao analisar uma tabela, seguir o fluxo: describe → stats → sample → queries específicas
CLAUDEMD_EOF
)

if [ -f "$CLAUDE_MD" ]; then
    # Remover bloco Databricks existente e substituir
    if grep -q "$MARKER" "$CLAUDE_MD"; then
        # Arquivo tem bloco Databricks — substituir
        # Pegar tudo ANTES do marcador
        BEFORE=$(sed "/$MARKER/,\$d" "$CLAUDE_MD")
        if [ -n "$BEFORE" ]; then
            printf '%s\n\n%s\n' "$BEFORE" "$DATABRICKS_BLOCK" > "$CLAUDE_MD"
        else
            echo "$DATABRICKS_BLOCK" > "$CLAUDE_MD"
        fi
    else
        # Arquivo existe mas não tem bloco Databricks — adicionar ao final
        printf '\n\n%s\n' "$DATABRICKS_BLOCK" >> "$CLAUDE_MD"
    fi
else
    echo "$DATABRICKS_BLOCK" > "$CLAUDE_MD"
fi
echo -e "  ${GREEN}✓${RESET} CLAUDE.md instalado"

# ── 6. Registrar MCP server via Claude CLI ───────────────────

MCP_URL="${SERVER_URL}/mcp"

if command -v claude &>/dev/null; then
    # Remover config anterior se existir
    claude mcp remove databricks -s user 2>/dev/null || true

    # Montar headers
    HEADER_ARGS="-H \"X-API-Key: ${API_KEY}\" -H \"X-Databricks-Host: ${DB_HOST}\" -H \"X-Databricks-Token: ${DB_TOKEN}\""
    if [ -n "$DB_WAREHOUSE" ]; then
        HEADER_ARGS="${HEADER_ARGS} -H \"X-Databricks-Warehouse-Id: ${DB_WAREHOUSE}\""
    fi

    # Registrar via Claude CLI (gera o formato correto em ~/.claude.json)
    eval claude mcp add -t http -s user ${HEADER_ARGS} databricks "${MCP_URL}"
    echo -e "  ${GREEN}✓${RESET} MCP server registrado via Claude CLI"
else
    echo -e "  ${YELLOW}!${RESET} Claude Code não encontrado. Após instalar, rode:"
    echo ""
    echo -e "    ${CYAN}claude mcp add -t http -s user \\"
    echo -e "      -H \"X-API-Key: \${API_KEY}\" \\"
    echo -e "      -H \"X-Databricks-Host: \${DB_HOST}\" \\"
    echo -e "      -H \"X-Databricks-Token: \${DB_TOKEN}\" \\"
    echo -e "      databricks ${MCP_URL}${RESET}"
    echo ""
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Instalação completa!${RESET}"
echo ""
echo "  Reinicie o Claude Code para ativar:"
echo -e "    ${CYAN}exit${RESET}  e depois  ${CYAN}claude${RESET}"
echo ""
echo "  O Databricks MCP já está disponível em qualquer projeto."
echo ""
echo -e "  ${DIM}Servidor: $SERVER_URL${RESET}"
echo -e "  ${DIM}Config:   $CFG_FILE${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
