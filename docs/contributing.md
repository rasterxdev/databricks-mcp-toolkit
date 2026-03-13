# Contribuição e Onboarding

## Para novos membros do time

1. Rode no terminal:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/rasterxdev/databricks-mcp-toolkit/main/setup.sh | bash
   ```
2. O instalador pedira o token Databricks (ver abaixo como gerar)
3. Pronto — qualquer terminal com Claude Code ja funciona

---

## Gerando seu token Databricks

1. Acesse o workspace: `https://<seu-workspace>.cloud.databricks.com/`
2. Clique no seu perfil (canto superior direito) → **Settings**
3. Va em **Developer** → **Access tokens**
4. Clique em **Generate new token**
5. Copie o token e cole quando o instalador pedir

---

## O que vai no git vs o que fica local

| Vai no git (este repo) | Fica local (por maquina) |
|---|---|
| `databricks_mcp/server.py` | `~/.local/share/databricks-mcp/` (instalação + credenciais) |
| `.claude/commands/*.md` | `~/.claude/` (modo global: agentes, skills, MCP config) |
| `.claude/agents/*.md` | `.env` (override de credenciais por projeto) |
| `scripts/install.sh` | `.claude/settings.local.json` (permissões locais) |
| `CLAUDE.md`, `README.md` | |

---

## Versionamento e Releases

O projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/) e usa [Conventional Commits](https://www.conventionalcommits.org/) para mensagens de commit (`feat:`, `fix:`, `docs:`).

### Criando uma release

```bash
./scripts/release.sh patch   # 0.1.0 → 0.1.1  (correções)
./scripts/release.sh minor   # 0.1.0 → 0.2.0  (novas funcionalidades)
./scripts/release.sh major   # 0.1.0 → 1.0.0  (breaking changes)
```

O script automatiza todo o processo:

1. Incrementa a versão no arquivo `VERSION`
2. Gera o changelog a partir dos commits desde a ultima tag
3. Cria um branch `release/vX.Y.Z` com o commit e tag anotada
4. Abre um Pull Request no GitHub para revisão

Apos o merge do PR, publique a release:

```bash
./scripts/post-release.sh vX.Y.Z
```

Isso faz push da tag, cria a GitHub Release com as notas do changelog e limpa o branch de release.

O changelog completo esta em [CHANGELOG.md](../CHANGELOG.md).
