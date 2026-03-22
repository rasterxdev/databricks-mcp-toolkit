# Contribuição e Onboarding

## Para novos membros do time

1. Obtenha com o admin do time: **URL do servidor MCP** e **API Key**
2. Rode no terminal:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/rasterxtech/databricks-mcp-toolkit/main/setup.sh | bash
   ```
3. O instalador pedirá: URL do servidor, API Key, e token Databricks (ver abaixo como gerar)
4. Reinicie o Claude Code e pronto

---

## Gerando seu token Databricks

1. Acesse o workspace: `https://<seu-workspace>.cloud.databricks.com/`
2. Clique no seu perfil (canto superior direito) → **Settings**
3. Vá em **Developer** → **Access tokens**
4. Clique em **Generate new token**
5. Copie o token e cole quando o instalador pedir

---

## O que vai no git vs o que fica local

| Vai no git (este repo) | Fica local (por maquina) |
|---|---|
| `databricks_mcp/server.py` | `~/.local/share/databricks-mcp/.databricks_mcp_cfg` (credenciais) |
| `Dockerfile`, `requirements.txt` | `~/.claude/commands/`, `~/.claude/agents/` (skills e agentes) |
| `.claude/commands/*.md` | `~/.claude.json` (config MCP, gerado por `claude mcp add`) |
| `.claude/agents/*.md` | |
| `CLAUDE.md`, `README.md` | |

---

## Fluxo de trabalho

O projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/) e usa [Conventional Commits](https://www.conventionalcommits.org/) para mensagens de commit (`feat:`, `fix:`, `docs:`).

### Branches

| Branch | Propósito | Recebe commits diretos? |
|---|---|---|
| `main` | Branch protegida, sempre estável | **Não** — só via PR |
| `develop` | Desenvolvimento ativo | Sim |
| `feat/<nome>` | Features grandes (opcional) | Sim |
| `release/vX.Y.Z` | Gerado pelo script de release | Não (automático) |

### Desenvolvimento

```bash
git checkout develop                    # usar branch de desenvolvimento
# ... fazer alterações e commits ...
git push -u origin develop
gh pr create --base main --head develop  # abrir PR para main
```

Após revisão, mergear o PR no GitHub.

### Criando uma release

Após o merge na main:

```bash
git checkout main && git pull
./scripts/release.sh patch   # 0.1.0 → 0.1.1  (correções)
./scripts/release.sh minor   # 0.1.0 → 0.2.0  (novas funcionalidades)
./scripts/release.sh major   # 0.1.0 → 1.0.0  (breaking changes)
```

O script automatiza: bump de versão, changelog, commit, tag e PR.

Após o merge do PR de release, publique:

```bash
./scripts/post-release.sh vX.Y.Z
```

Isso faz push da tag, cria a GitHub Release com as notas do changelog e limpa o branch de release.

O changelog completo está em [CHANGELOG.md](../CHANGELOG.md).
