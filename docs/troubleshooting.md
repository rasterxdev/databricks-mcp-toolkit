# Troubleshooting

| Problema | Solução |
|---|---|
| MCP Server não aparece | Reinicie o Claude Code (`exit` + `claude`) |
| Erro de autenticação | Verifique `~/.local/share/databricks-mcp/.databricks_mcp_cfg` ou o `.env` do projeto |
| Nenhum warehouse disponível | Acesse o workspace e inicie um SQL Warehouse |
| `wait_timeout` error | O timeout máximo da API é 50s, queries longas podem precisar de polling |
| Python não encontrado | Verifique se tem Python 3.10+ instalado (`python3 --version`) |
| Erro ao criar venv | Instale o módulo venv: `sudo apt install python3.X-venv` (substitua X pela sua versão) |
| `databricks-mcp-init` não encontrado | Apenas modo por projeto — rode `source ~/.zshrc` ou abra um novo terminal |
| Skills não aparecem | Verifique se `.claude/commands/` existe e tem os arquivos `.md` |

## Prioridade de credenciais

O servidor segue esta ordem de prioridade:

1. **`.env` do projeto** — override local (se existir)
2. **`.databricks_mcp_cfg`** — credenciais globais (criadas pelo instalador)
3. **Perfil CLI** — `~/.databrickscfg` (fallback)

> `DATABRICKS_WAREHOUSE_ID` é opcional em qualquer modo. Se omitido, o servidor usa automaticamente o primeiro warehouse em estado `RUNNING`.
