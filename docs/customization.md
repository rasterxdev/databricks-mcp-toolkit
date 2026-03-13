# Customização

## Credenciais

As credenciais são configuradas durante a instalação e salvas em `~/.local/share/databricks-mcp/.databricks_mcp_cfg`. Para override por projeto, crie um `.env` na raiz do projeto.

| Variavel | Obrigatoria | Descrição |
|---|---|---|
| `DATABRICKS_HOST` | Sim | URL do workspace (ex: `https://dbc-xxx.cloud.databricks.com/`) |
| `DATABRICKS_TOKEN` | Sim | Token de acesso pessoal (PAT) |
| `DATABRICKS_WAREHOUSE_ID` | Não | ID do SQL Warehouse. Se omitido, usa o primeiro em estado `RUNNING` |

Para reconfigurar credenciais, rode `./scripts/install.sh` novamente — o instalador detecta credenciais existentes e oferece a opção de mante-las ou substitui-las.

---

## Adicionar novas ferramentas ao MCP Server

Edite `databricks_mcp/server.py` e adicione uma nova função decorada com `@mcp.tool()`:

```python
@mcp.tool()
def minha_ferramenta(parametro: str) -> str:
    """Descrição da ferramenta.

    Args:
        parametro: Descrição do parâmetro.
    """
    client = _get_client()
    # sua logica aqui
    return "resultado"
```

Apos editar, rode `./scripts/install.sh` novamente para atualizar a instalação global.

---

## Adicionar novas skills

Crie um arquivo `.md` em `.claude/commands/`:

```markdown
---
description: Descrição curta da skill
allowed-tools: mcp__databricks__run_sql, mcp__databricks__describe_table
---

Instruções para o Claude sobre o que fazer.

$ARGUMENTS
```

A skill fica disponível imediatamente como `/nome-do-arquivo`. Rode `./scripts/install.sh` para atualizar os templates globais.
