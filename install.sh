#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Databricks MCP - Instalador global
#
# Instala o MCP Server, skills e agent em ~/.local/share/databricks-mcp/
# para uso com Claude Code em qualquer projeto.
# ─────────────────────────────────────────────────────────────

set -e

MCP_HOME="$HOME/.local/share/databricks-mcp"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 Instalando Databricks MCP Toolkit..."
echo "   Origem: $SCRIPT_DIR"
echo "   Destino: $MCP_HOME"
echo ""

# 1. Criar diretório
mkdir -p "$MCP_HOME/commands" "$MCP_HOME/agents"

# 2. Copiar server
cp "$SCRIPT_DIR/databricks_mcp/server.py" "$MCP_HOME/server.py"
echo "✅ MCP Server copiado"

# 3. Copiar skills e agent
cp "$SCRIPT_DIR/.claude/commands/"*.md "$MCP_HOME/commands/" 2>/dev/null || true
cp "$SCRIPT_DIR/.claude/agents/"*.md "$MCP_HOME/agents/" 2>/dev/null || true
echo "✅ Skills e agent copiados"

# 4. Criar setup script (usado pelo comando databricks-mcp-init)
cat > "$MCP_HOME/setup.sh" << 'SETUP_EOF'
#!/bin/bash
set -e
MCP_HOME="$HOME/.local/share/databricks-mcp"
PROJECT_DIR="$(pwd)"
echo "🔧 Databricks MCP Setup"
echo "   Projeto: $PROJECT_DIR"
echo ""
cat > "$PROJECT_DIR/.mcp.json" << EOF
{
  "mcpServers": {
    "databricks": {
      "command": "$MCP_HOME/.venv/bin/python",
      "args": ["$MCP_HOME/server.py"]
    }
  }
}
EOF
echo "✅ .mcp.json criado"
if [ -f "$PROJECT_DIR/.gitignore" ]; then
    if ! grep -q "^\.mcp\.json$" "$PROJECT_DIR/.gitignore"; then
        echo ".mcp.json" >> "$PROJECT_DIR/.gitignore"
        echo "✅ .mcp.json adicionado ao .gitignore"
    fi
else
    echo ".mcp.json" > "$PROJECT_DIR/.gitignore"
    echo "✅ .gitignore criado com .mcp.json"
fi
mkdir -p "$PROJECT_DIR/.claude/commands" "$PROJECT_DIR/.claude/agents"
for file in sql.md analyze.md notebook.md explore.md predict.md stats.md timeseries.md model.md feature.md; do
    [ -f "$MCP_HOME/commands/$file" ] && cp "$MCP_HOME/commands/$file" "$PROJECT_DIR/.claude/commands/$file"
done
for file in databricks-analyst.md data-scientist.md; do
    [ -f "$MCP_HOME/agents/$file" ] && cp "$MCP_HOME/agents/$file" "$PROJECT_DIR/.claude/agents/"
done
echo "✅ Skills e agents copiados para .claude/"
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo ""
    echo "⚠️  Crie o .env com suas credenciais:"
    echo "   DATABRICKS_HOST=https://seu-workspace.cloud.databricks.com/"
    echo "   DATABRICKS_TOKEN=dapi..."
fi
echo ""
echo "🚀 Setup completo! Reinicie o Claude Code neste diretório."
SETUP_EOF
chmod +x "$MCP_HOME/setup.sh"
echo "✅ Setup script configurado"

# 5. Criar/atualizar venv
if [ ! -d "$MCP_HOME/.venv" ]; then
    echo "📦 Criando ambiente virtual..."
    python3 -m venv "$MCP_HOME/.venv"
    "$MCP_HOME/.venv/bin/pip" install --quiet databricks-connect databricks-sdk "mcp[cli]" python-dotenv
    echo "✅ Ambiente virtual criado e dependências instaladas"
else
    echo "⏭️  Ambiente virtual já existe, atualizando dependências..."
    "$MCP_HOME/.venv/bin/pip" install --quiet --upgrade databricks-connect databricks-sdk "mcp[cli]" python-dotenv
    echo "✅ Dependências atualizadas"
fi

# 6. Configurar gitignore global
GLOBAL_GITIGNORE="$HOME/.gitignore_global"
if [ ! -f "$GLOBAL_GITIGNORE" ] || ! grep -q "^\.mcp\.json$" "$GLOBAL_GITIGNORE"; then
    echo ".mcp.json" >> "$GLOBAL_GITIGNORE"
    git config --global core.excludesfile "$GLOBAL_GITIGNORE"
    echo "✅ .mcp.json adicionado ao gitignore global"
else
    echo "⏭️  Gitignore global já configurado"
fi

# 7. Adicionar alias ao shell
SHELL_RC="$HOME/.$(basename "$SHELL")rc"
if [ -f "$SHELL_RC" ] && ! grep -q "databricks-mcp-init" "$SHELL_RC"; then
    echo '' >> "$SHELL_RC"
    echo '# Databricks MCP - setup para projetos Claude Code' >> "$SHELL_RC"
    echo "alias databricks-mcp-init=\"$MCP_HOME/setup.sh\"" >> "$SHELL_RC"
    echo "✅ Alias 'databricks-mcp-init' adicionado ao $SHELL_RC"
else
    echo "⏭️  Alias já configurado"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "  🚀 Instalação completa!"
echo ""
echo "  Para usar em qualquer projeto:"
echo "    1. cd ~/meu-projeto"
echo "    2. databricks-mcp-init"
echo "    3. Crie o .env com suas credenciais"
echo "    4. claude"
echo ""
echo "  (abra um novo terminal ou rode: source $SHELL_RC)"
echo "════════════════════════════════════════════════════"
