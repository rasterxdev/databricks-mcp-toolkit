#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Databricks MCP Toolkit — Instalador
#
# Instala o MCP Server globalmente e configura credenciais,
# agentes e skills para uso com Claude Code.
# ─────────────────────────────────────────────────────────────

set -e

MCP_HOME="$HOME/.local/share/databricks-mcp"
CLAUDE_GLOBAL="$HOME/.claude"
CFG_FILE="$MCP_HOME/.databricks_mcp_cfg"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "══════════════════════════════════════════════════════════"
echo "  Databricks MCP Toolkit — Instalador"
echo "══════════════════════════════════════════════════════════"
echo ""
echo "  Origem:  $SCRIPT_DIR"
echo "  Destino: $MCP_HOME"
echo ""

# ── 1. Criar diretórios e copiar server ─────────────────────

mkdir -p "$MCP_HOME/commands" "$MCP_HOME/agents"

cp "$SCRIPT_DIR/databricks_mcp/server.py" "$MCP_HOME/server.py"
echo "✅ MCP Server copiado"

cp "$SCRIPT_DIR/.claude/commands/"*.md "$MCP_HOME/commands/" 2>/dev/null || true
cp "$SCRIPT_DIR/.claude/agents/"*.md "$MCP_HOME/agents/" 2>/dev/null || true
echo "✅ Skills e agents copiados para $MCP_HOME/"

# ── 2. Checar pré-requisitos ─────────────────────────────────

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 10 ]; }; then
    echo "❌ Python 3.10+ é necessário (encontrado: $PYTHON_VERSION)"
    exit 1
fi

if ! python3 -c "import venv" &>/dev/null; then
    echo ""
    echo "❌ Módulo venv não encontrado."
    echo ""
    echo "  No Ubuntu/Debian, instale com:"
    echo "    sudo apt install python${PYTHON_VERSION}-venv"
    echo ""
    echo "  No Fedora/RHEL:"
    echo "    sudo dnf install python3-libs"
    echo ""
    exit 1
fi

# ── 3. Criar/atualizar ambiente virtual ──────────────────────

if [ ! -d "$MCP_HOME/.venv" ]; then
    echo ""
    echo "📦 Criando ambiente virtual..."
    python3 -m venv "$MCP_HOME/.venv"
    "$MCP_HOME/.venv/bin/pip" install --quiet databricks-connect databricks-sdk "mcp[cli]" python-dotenv
    echo "✅ Ambiente virtual criado e dependências instaladas"
else
    echo "⏭️  Ambiente virtual existente, atualizando dependências..."
    "$MCP_HOME/.venv/bin/pip" install --quiet --upgrade databricks-connect databricks-sdk "mcp[cli]" python-dotenv
    echo "✅ Dependências atualizadas"
fi

# ── 4. Credenciais ──────────────────────────────────────────

echo ""
echo "──────────────────────────────────────────────────────────"
echo "  Credenciais Databricks"
echo "──────────────────────────────────────────────────────────"
echo ""

CONFIGURE_CREDS="s"

if [ -f "$CFG_FILE" ]; then
    echo "  Credenciais existentes encontradas em:"
    echo "  $CFG_FILE"
    echo ""
    read -r -p "  Deseja manter as credenciais atuais? [S/n] " KEEP_CREDS
    KEEP_CREDS=${KEEP_CREDS:-S}
    if [[ "$KEEP_CREDS" =~ ^[sS] ]]; then
        CONFIGURE_CREDS="n"
        echo ""
        echo "  ✅ Credenciais mantidas"
    fi
fi

if [ "$CONFIGURE_CREDS" = "s" ]; then
    echo ""
    echo "  Informe suas credenciais do Databricks."
    echo "  (Para gerar um token: Workspace → Settings → Developer → Access tokens)"
    echo ""

    read -r -p "  DATABRICKS_HOST (ex: https://dbc-xxx.cloud.databricks.com/): " DB_HOST
    while [ -z "$DB_HOST" ]; do
        echo "  ❌ DATABRICKS_HOST é obrigatório."
        read -r -p "  DATABRICKS_HOST: " DB_HOST
    done

    read -r -s -p "  DATABRICKS_TOKEN (input oculto): " DB_TOKEN
    echo ""
    while [ -z "$DB_TOKEN" ]; do
        echo "  ❌ DATABRICKS_TOKEN é obrigatório."
        read -r -s -p "  DATABRICKS_TOKEN: " DB_TOKEN
        echo ""
    done

    read -r -p "  DATABRICKS_WAREHOUSE_ID (opcional, Enter para auto-detectar): " DB_WAREHOUSE

    # Salvar credenciais
    cat > "$CFG_FILE" << EOF
DATABRICKS_HOST=$DB_HOST
DATABRICKS_TOKEN=$DB_TOKEN
EOF

    if [ -n "$DB_WAREHOUSE" ]; then
        echo "DATABRICKS_WAREHOUSE_ID=$DB_WAREHOUSE" >> "$CFG_FILE"
    fi

    chmod 600 "$CFG_FILE"
    echo ""
    echo "  ✅ Credenciais salvas em $CFG_FILE"
fi

# ── 5. Modo de instalação ──────────────────────────────────

echo ""
echo "──────────────────────────────────────────────────────────"
echo "  Modo de Instalação"
echo "──────────────────────────────────────────────────────────"
echo ""
echo "  [1] ⭐ GLOBAL (recomendado)"
echo "      Instala agentes, skills e MCP no ~/.claude/"
echo "      Funciona em qualquer terminal com Claude Code."
echo "      Não precisa configurar nada por projeto."
echo ""
echo "  [2] Por projeto"
echo "      Rode 'databricks-mcp-init' em cada projeto"
echo "      para copiar agentes, skills e .mcp.json."
echo ""

read -r -p "  Escolha [1/2] (padrão: 1): " INSTALL_MODE
INSTALL_MODE=${INSTALL_MODE:-1}

if [ "$INSTALL_MODE" = "1" ]; then
    # ── Instalação Global ───────────────────────────────────
    echo ""
    echo "  📦 Instalando globalmente em $CLAUDE_GLOBAL/ ..."
    echo ""

    # Criar diretórios globais
    mkdir -p "$CLAUDE_GLOBAL/commands" "$CLAUDE_GLOBAL/agents"

    # Copiar agents e skills
    cp "$SCRIPT_DIR/.claude/commands/"*.md "$CLAUDE_GLOBAL/commands/" 2>/dev/null || true
    cp "$SCRIPT_DIR/.claude/agents/"*.md "$CLAUDE_GLOBAL/agents/" 2>/dev/null || true
    echo "  ✅ Agentes e skills instalados em $CLAUDE_GLOBAL/"

    # Copiar CLAUDE.md global
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
    echo "  ✅ CLAUDE.md instalado em $CLAUDE_GLOBAL/"

    # Criar/atualizar .mcp.json global (merge seguro com config existente)
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
    echo "  ✅ .mcp.json configurado em $CLAUDE_GLOBAL/"

    # Salvar modo de instalação
    echo "mode=global" > "$MCP_HOME/.install_mode"

    # Configurar gitignore global (ainda útil para quem faz init por projeto)
    GLOBAL_GITIGNORE="$HOME/.gitignore_global"
    if [ ! -f "$GLOBAL_GITIGNORE" ] || ! grep -q "^\.mcp\.json$" "$GLOBAL_GITIGNORE"; then
        echo ".mcp.json" >> "$GLOBAL_GITIGNORE"
        git config --global core.excludesfile "$GLOBAL_GITIGNORE"
    fi

    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "  🚀 Instalação global completa!"
    echo ""
    echo "  Abra qualquer terminal e rode:"
    echo "    claude"
    echo ""
    echo "  O Databricks MCP já está disponível em qualquer projeto."
    echo "  Suas credenciais estão salvas em:"
    echo "    $CFG_FILE"
    echo ""
    echo "  Para override por projeto, crie um .env local com"
    echo "  DATABRICKS_HOST e DATABRICKS_TOKEN."
    echo "══════════════════════════════════════════════════════════"

else
    # ── Instalação Por Projeto ──────────────────────────────
    echo ""
    echo "  📦 Configurando modo por projeto..."
    echo ""

    # Criar setup.sh (usado pelo databricks-mcp-init)
    cat > "$MCP_HOME/setup.sh" << 'SETUP_EOF'
#!/bin/bash
set -e

MCP_HOME="$HOME/.local/share/databricks-mcp"
PROJECT_DIR="$(pwd)"

echo ""
echo "🔧 Databricks MCP Setup"
echo "   Projeto: $PROJECT_DIR"
echo ""

# Gerar .mcp.json do projeto
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

# Atualizar .gitignore
if [ -f "$PROJECT_DIR/.gitignore" ]; then
    if ! grep -q "^\.mcp\.json$" "$PROJECT_DIR/.gitignore"; then
        echo ".mcp.json" >> "$PROJECT_DIR/.gitignore"
        echo "✅ .mcp.json adicionado ao .gitignore"
    fi
else
    echo ".mcp.json" > "$PROJECT_DIR/.gitignore"
    echo "✅ .gitignore criado com .mcp.json"
fi

# Copiar agents e skills para o projeto
mkdir -p "$PROJECT_DIR/.claude/commands" "$PROJECT_DIR/.claude/agents"

for file in sql.md analyze.md notebook.md explore.md predict.md stats.md timeseries.md model.md feature.md; do
    [ -f "$MCP_HOME/commands/$file" ] && cp "$MCP_HOME/commands/$file" "$PROJECT_DIR/.claude/commands/$file"
done

for file in databricks-analyst.md data-scientist.md; do
    [ -f "$MCP_HOME/agents/$file" ] && cp "$MCP_HOME/agents/$file" "$PROJECT_DIR/.claude/agents/"
done

echo "✅ Skills e agents copiados para .claude/"
echo ""
echo "🚀 Setup completo! Reinicie o Claude Code neste diretório."
echo ""
echo "   Suas credenciais globais serão usadas automaticamente."
echo "   Para override local, crie um .env com DATABRICKS_HOST e DATABRICKS_TOKEN."
SETUP_EOF
    chmod +x "$MCP_HOME/setup.sh"
    echo "  ✅ Setup script configurado"

    # Salvar modo de instalação
    echo "mode=project" > "$MCP_HOME/.install_mode"

    # Configurar gitignore global
    GLOBAL_GITIGNORE="$HOME/.gitignore_global"
    if [ ! -f "$GLOBAL_GITIGNORE" ] || ! grep -q "^\.mcp\.json$" "$GLOBAL_GITIGNORE"; then
        echo ".mcp.json" >> "$GLOBAL_GITIGNORE"
        git config --global core.excludesfile "$GLOBAL_GITIGNORE"
    fi

    # Adicionar alias ao shell
    SHELL_RC="$HOME/.$(basename "$SHELL")rc"
    if [ -f "$SHELL_RC" ] && ! grep -q "databricks-mcp-init" "$SHELL_RC"; then
        echo '' >> "$SHELL_RC"
        echo '# Databricks MCP - setup para projetos Claude Code' >> "$SHELL_RC"
        echo "alias databricks-mcp-init=\"$MCP_HOME/setup.sh\"" >> "$SHELL_RC"
        echo "  ✅ Alias 'databricks-mcp-init' adicionado ao $SHELL_RC"
    else
        echo "  ⏭️  Alias já configurado"
    fi

    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "  🚀 Instalação completa!"
    echo ""
    echo "  Para usar em qualquer projeto:"
    echo "    1. cd ~/meu-projeto"
    echo "    2. databricks-mcp-init"
    echo "    3. claude"
    echo ""
    echo "  Suas credenciais estão salvas globalmente em:"
    echo "    $CFG_FILE"
    echo ""
    echo "  (abra um novo terminal ou rode: source $SHELL_RC)"
    echo "══════════════════════════════════════════════════════════"
fi
