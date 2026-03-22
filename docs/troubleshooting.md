# Troubleshooting

| Problema | Solução |
|---|---|
| MCP tools no aparecem | Reinicie o Claude Code (`exit` + `claude`) |
| Erro de autenticacao | Verifique `~/.local/share/databricks-mcp/.databricks_mcp_cfg` e reconfigure com `setup.sh` |
| "Invalid or missing X-API-Key" | API Key incorreta. Verifique a env var `MCP_API_KEY` no servidor e o header local |
| Nenhum warehouse disponivel | Acesse o workspace Databricks e inicie um SQL Warehouse |
| `wait_timeout` error | O timeout maximo da API e 50s, queries longas podem precisar de polling |
| Cold start demorado (~1min) | Normal no Render free tier. O server dorme apos 15min sem uso |
| Skills nao aparecem | Verifique se `~/.claude/commands/` existe e tem os arquivos `.md` |
| MCP nao registrado | Rode `claude mcp add -t http -s user -H "X-API-Key: ..." databricks URL` |

## Verificar configuracao MCP

```bash
# Ver servers MCP registrados
claude mcp list

# Testar health check do server
curl https://SEU-SERVER.onrender.com/health

# Testar autenticacao
curl -H "X-API-Key: SUA_KEY" https://SEU-SERVER.onrender.com/mcp
```

## Reconfigurar credenciais

Rode o instalador novamente — ele detecta credenciais existentes e oferece a opcao de substituir:

```bash
curl -fsSL https://raw.githubusercontent.com/rasterxtech/databricks-mcp-toolkit/main/setup.sh | bash
```
