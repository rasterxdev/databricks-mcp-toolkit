#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Databricks MCP Toolkit — Atualizador
#
# Baixa a versão mais recente do GitHub e atualiza os arquivos
# locais. Não altera credenciais.
# ─────────────────────────────────────────────────────────────

set -e

REPO_RAW="https://raw.githubusercontent.com/rasterxdev/databricks-mcp-toolkit/main"
MCP_HOME="$HOME/.local/share/databricks-mcp"
CLAUDE_GLOBAL="$HOME/.claude"

# ── Cores ────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD="\033[1m" DIM="\033[2m" RESET="\033[0m"
    GREEN="\033[32m" YELLOW="\033[33m" CYAN="\033[36m"
else
    BOLD="" DIM="" RESET="" GREEN="" YELLOW="" CYAN=""
fi

# ── Verificar versão ────────────────────────────────────────

LOCAL_VERSION="desconhecida"
if [ -f "$MCP_HOME/.version" ]; then
    LOCAL_VERSION=$(cat "$MCP_HOME/.version")
fi

REMOTE_VERSION=$(curl -fsSL "$REPO_RAW/VERSION" 2>/dev/null || echo "")

if [ -z "$REMOTE_VERSION" ]; then
    echo -e "  ${YELLOW}❌${RESET} Não foi possível verificar a versão remota."
    exit 1
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Databricks MCP Toolkit — Atualizador${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  Versão local:  ${YELLOW}${LOCAL_VERSION}${RESET}"
echo -e "  Versão remota: ${GREEN}${REMOTE_VERSION}${RESET}"
echo ""

if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
    echo -e "  ${GREEN}✓${RESET} Você já está na versão mais recente."
    echo ""
    exit 0
fi

# ── Baixar arquivos ──────────────────────────────────────────

echo -e "${BOLD}  📥 Baixando arquivos...${RESET}"
echo ""

mkdir -p "$MCP_HOME/commands" "$MCP_HOME/agents"

curl -fsSL "$REPO_RAW/databricks_mcp/server.py" -o "$MCP_HOME/server.py"
echo -e "  ${GREEN}✓${RESET} MCP Server"

SKILLS="sql analyze notebook explore predict stats timeseries model feature"
for skill in $SKILLS; do
    curl -fsSL "$REPO_RAW/.claude/commands/${skill}.md" -o "$MCP_HOME/commands/${skill}.md"
done
echo -e "  ${GREEN}✓${RESET} Skills"

AGENTS="databricks-analyst data-scientist"
for agent in $AGENTS; do
    curl -fsSL "$REPO_RAW/.claude/agents/${agent}.md" -o "$MCP_HOME/agents/${agent}.md"
done
echo -e "  ${GREEN}✓${RESET} Agentes"

# Baixar o próprio update.sh e a skill de update
curl -fsSL "$REPO_RAW/update.sh" -o "$MCP_HOME/update.sh"
chmod +x "$MCP_HOME/update.sh"
curl -fsSL "$REPO_RAW/.claude/commands/databricks-update.md" -o "$MCP_HOME/commands/databricks-update.md"
echo -e "  ${GREEN}✓${RESET} Atualizador"

# ── Atualizar dependências ───────────────────────────────────

echo ""
echo -e "  ${DIM}Atualizando dependências...${RESET}"
"$MCP_HOME/.venv/bin/pip" install --quiet --upgrade databricks-connect databricks-sdk "mcp[cli]" python-dotenv
echo -e "  ${GREEN}✓${RESET} Dependências atualizadas"

# ── Atualizar instalação global ──────────────────────────────

INSTALL_MODE="global"
if [ -f "$MCP_HOME/.install_mode" ]; then
    INSTALL_MODE=$(cat "$MCP_HOME/.install_mode" | cut -d= -f2)
fi

if [ "$INSTALL_MODE" = "global" ] && [ -d "$CLAUDE_GLOBAL" ]; then
    echo ""
    echo -e "  ${DIM}Atualizando instalação global...${RESET}"

    mkdir -p "$CLAUDE_GLOBAL/commands" "$CLAUDE_GLOBAL/agents"
    cp "$MCP_HOME/commands/"*.md "$CLAUDE_GLOBAL/commands/" 2>/dev/null || true
    cp "$MCP_HOME/agents/"*.md  "$CLAUDE_GLOBAL/agents/"   2>/dev/null || true
    echo -e "  ${GREEN}✓${RESET} Skills e agentes globais atualizados"
fi

# ── Salvar nova versão ───────────────────────────────────────

echo "$REMOTE_VERSION" > "$MCP_HOME/.version"

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  ✅ Atualizado: v${LOCAL_VERSION} → v${REMOTE_VERSION}${RESET}"
echo ""
echo "  Reinicie o Claude Code para aplicar:"
echo -e "    ${CYAN}exit${RESET}  e depois  ${CYAN}claude${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
