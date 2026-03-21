#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Databricks MCP Toolkit — Atualizador
#
# Atualiza agentes, skills e configuração local para a
# versão mais recente do repositório.
# Não altera credenciais nem configuração do servidor.
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
    echo -e "  ${YELLOW}!${RESET} Não foi possível verificar a versão remota."
    echo "  Verifique sua conexão com a internet."
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

# ── Baixar skills e agents ──────────────────────────────────

echo -e "  ${CYAN}Atualizando $LOCAL_VERSION → $REMOTE_VERSION ...${RESET}"
echo ""

mkdir -p "$MCP_HOME/commands" "$MCP_HOME/agents"

SKILLS="sql analyze notebook explore predict stats timeseries model feature databricks-update"
for skill in $SKILLS; do
    curl -fsSL "$REPO_RAW/.claude/commands/${skill}.md" -o "$MCP_HOME/commands/${skill}.md" 2>/dev/null || true
done
echo -e "  ${GREEN}✓${RESET} Skills atualizadas"

AGENTS="databricks-analyst data-scientist"
for agent in $AGENTS; do
    curl -fsSL "$REPO_RAW/.claude/agents/${agent}.md" -o "$MCP_HOME/agents/${agent}.md" 2>/dev/null || true
done
echo -e "  ${GREEN}✓${RESET} Agentes atualizados"

# Atualizar o próprio update.sh
curl -fsSL "$REPO_RAW/update.sh" -o "$MCP_HOME/update.sh" 2>/dev/null || true
chmod +x "$MCP_HOME/update.sh"

# ── Copiar para ~/.claude/ ───────────────────────────────────

if [ -d "$CLAUDE_GLOBAL" ]; then
    mkdir -p "$CLAUDE_GLOBAL/commands" "$CLAUDE_GLOBAL/agents"
    cp "$MCP_HOME/commands/"*.md "$CLAUDE_GLOBAL/commands/" 2>/dev/null || true
    cp "$MCP_HOME/agents/"*.md  "$CLAUDE_GLOBAL/agents/"   2>/dev/null || true
    echo -e "  ${GREEN}✓${RESET} Arquivos copiados para $CLAUDE_GLOBAL/"
fi

# ── Salvar nova versão ───────────────────────────────────────

echo "$REMOTE_VERSION" > "$MCP_HOME/.version"

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Atualizado: v${LOCAL_VERSION} → v${REMOTE_VERSION}${RESET}"
echo ""
echo -e "  ${YELLOW}Reinicie o Claude Code para aplicar as mudanças.${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${RESET}"
echo ""
