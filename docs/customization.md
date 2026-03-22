# Customizacao

## Credenciais

As credenciais sao configuradas durante a instalacao. O instalador salva uma copia local em `~/.local/share/databricks-mcp/.databricks_mcp_cfg` e registra o MCP server via `claude mcp add` com as credenciais nos headers HTTP.

| Configuracao | Obrigatoria | Descricao |
|---|---|---|
| `MCP_SERVER_URL` | Sim | URL do servidor MCP (ex: `https://databricks-mcp.onrender.com`) |
| `MCP_API_KEY` | Sim | Chave de acesso do servidor (fornecida pelo admin) |
| `DATABRICKS_HOST` | Sim | URL do workspace (ex: `https://dbc-xxx.cloud.databricks.com`) |
| `DATABRICKS_TOKEN` | Sim | Token de acesso pessoal (PAT) |
| `DATABRICKS_WAREHOUSE_ID` | Nao | ID do SQL Warehouse. Se omitido, usa o primeiro em estado `RUNNING` |

Para reconfigurar, rode o instalador novamente:

```bash
curl -fsSL https://raw.githubusercontent.com/rasterxtech/databricks-mcp-toolkit/main/setup.sh | bash
```

Ou reconfigure manualmente o MCP:

```bash
claude mcp remove databricks -s user
claude mcp add -t http -s user \
  -H "X-API-Key: SUA_KEY" \
  -H "X-Databricks-Host: https://seu-workspace.cloud.databricks.com" \
  -H "X-Databricks-Token: SEU_TOKEN" \
  databricks https://seu-server.onrender.com/mcp
```

---

## Adicionar novas ferramentas ao MCP Server

Edite `databricks_mcp/server.py` e adicione uma nova funcao decorada com `@mcp.tool()`:

```python
@mcp.tool()
def minha_ferramenta(parametro: str) -> str:
    """Descricao da ferramenta.

    Args:
        parametro: Descricao do parametro.
    """
    client = _get_client()
    # sua logica aqui
    return "resultado"
```

Apos editar, faca deploy do server (o Render redeploya automaticamente ao push na main).

---

## Adicionar novas skills

Crie um arquivo `.md` em `.claude/commands/`:

```markdown
---
description: Descricao curta da skill
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table
---

Instrucoes para o Claude sobre o que fazer.

$ARGUMENTS
```

A skill fica disponivel imediatamente como `/nome-do-arquivo`. Rode o instalador ou copie manualmente para `~/.claude/commands/`.
