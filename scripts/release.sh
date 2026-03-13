#!/usr/bin/env bash
# =============================================================================
# release.sh — Script de automação de releases para o Databricks MCP Toolkit
#
# Uso:
#   ./scripts/release.sh patch   # 0.1.0 → 0.1.1
#   ./scripts/release.sh minor   # 0.1.0 → 0.2.0
#   ./scripts/release.sh major   # 0.1.0 → 1.0.0
#
# O que faz:
#   1. Incrementa a versão no arquivo VERSION
#   2. Gera changelog a partir dos commits desde a última tag
#   3. Cria commit e tag anotada
#   4. Cria PR via gh CLI
# =============================================================================
set -euo pipefail

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # sem cor

# --- Funções de output ---
info()  { echo -e "${BLUE}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
error() { echo -e "${RED}[erro]${NC}  $*" >&2; }
fatal() { error "$*"; exit 1; }

# --- Constantes ---
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$REPO_ROOT/VERSION"
CHANGELOG_FILE="$REPO_ROOT/CHANGELOG.md"
GITHUB_REPO="rasterxdev/databricks-mcp-toolkit"

# =============================================================================
# Validações
# =============================================================================

# Argumento obrigatório
BUMP_TYPE="${1:-}"
if [[ -z "$BUMP_TYPE" ]]; then
    echo -e "${BOLD}Uso:${NC} $0 <patch|minor|major>"
    echo ""
    echo "  patch  — incrementa o terceiro número (0.1.0 → 0.1.1)"
    echo "  minor  — incrementa o segundo número (0.1.0 → 0.2.0)"
    echo "  major  — incrementa o primeiro número (0.1.0 → 1.0.0)"
    exit 1
fi

if [[ "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
    fatal "Tipo de bump inválido: '$BUMP_TYPE'. Use: patch, minor ou major."
fi

# Verifica se está na raiz do repositório
if [[ ! -f "$VERSION_FILE" ]]; then
    fatal "Arquivo VERSION não encontrado em $REPO_ROOT"
fi

# Verifica dependências: git e gh
if ! command -v git &>/dev/null; then
    fatal "git não encontrado. Instale antes de continuar."
fi

if ! command -v gh &>/dev/null; then
    fatal "GitHub CLI (gh) não encontrado. Instale: https://cli.github.com/"
fi

# Verifica autenticação do gh
if ! gh auth status &>/dev/null; then
    fatal "gh CLI não está autenticado. Rode: gh auth login"
fi

# Verifica se está no branch main
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    fatal "Você precisa estar no branch 'main' para criar uma release. Branch atual: '$CURRENT_BRANCH'"
fi

# Verifica se o working tree está limpo
if ! git diff --quiet || ! git diff --cached --quiet; then
    fatal "Working tree não está limpo. Faça commit ou stash das alterações antes de continuar."
fi

# Verifica se há arquivos untracked (exceto os que o script vai criar)
UNTRACKED="$(git ls-files --others --exclude-standard | grep -v '^CHANGELOG.md$' || true)"
if [[ -n "$UNTRACKED" ]]; then
    fatal "Há arquivos untracked no repositório. Faça commit ou adicione ao .gitignore:\n$UNTRACKED"
fi

ok "Validações passaram"

# =============================================================================
# Calcula nova versão
# =============================================================================

CURRENT_VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"

# Separa os componentes major.minor.patch
IFS='.' read -r V_MAJOR V_MINOR V_PATCH <<< "$CURRENT_VERSION"

# Valida que os componentes são números
if ! [[ "$V_MAJOR" =~ ^[0-9]+$ && "$V_MINOR" =~ ^[0-9]+$ && "$V_PATCH" =~ ^[0-9]+$ ]]; then
    fatal "Formato de versão inválido em VERSION: '$CURRENT_VERSION'. Esperado: X.Y.Z"
fi

case "$BUMP_TYPE" in
    major)
        V_MAJOR=$((V_MAJOR + 1))
        V_MINOR=0
        V_PATCH=0
        ;;
    minor)
        V_MINOR=$((V_MINOR + 1))
        V_PATCH=0
        ;;
    patch)
        V_PATCH=$((V_PATCH + 1))
        ;;
esac

NEW_VERSION="${V_MAJOR}.${V_MINOR}.${V_PATCH}"
TAG_NAME="v${NEW_VERSION}"
RELEASE_BRANCH="release/${TAG_NAME}"
RELEASE_DATE="$(date +%Y-%m-%d)"

info "Versão atual:  ${BOLD}${CURRENT_VERSION}${NC}"
info "Nova versão:   ${BOLD}${NEW_VERSION}${NC} (${BUMP_TYPE})"
info "Tag:           ${BOLD}${TAG_NAME}${NC}"
info "Branch:        ${BOLD}${RELEASE_BRANCH}${NC}"
echo ""

# Confirmação do usuário
read -p "Continuar com a release ${TAG_NAME}? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Release cancelada."
    exit 0
fi

# Verifica se a tag já existe
if git rev-parse "$TAG_NAME" &>/dev/null; then
    fatal "Tag '$TAG_NAME' já existe. Escolha outro tipo de bump ou remova a tag existente."
fi

# Verifica se o branch de release já existe
if git rev-parse --verify "$RELEASE_BRANCH" &>/dev/null; then
    fatal "Branch '$RELEASE_BRANCH' já existe. Remova-o antes de continuar: git branch -d $RELEASE_BRANCH"
fi

# =============================================================================
# Gera changelog a partir dos commits
# =============================================================================

info "Gerando changelog..."

# Determina o range de commits: desde a última tag ou desde o início
LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
if [[ -n "$LAST_TAG" ]]; then
    COMMIT_RANGE="${LAST_TAG}..HEAD"
    COMPARE_FROM="$LAST_TAG"
else
    # Sem tags anteriores — pega todos os commits
    COMMIT_RANGE="HEAD"
    COMPARE_FROM="$(git rev-list --max-parents=0 HEAD | head -1)"
fi

# Coleta commits agrupados por tipo
declare -a FEAT_COMMITS=()
declare -a FIX_COMMITS=()
declare -a DOCS_COMMITS=()
declare -a OTHER_COMMITS=()

while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Ignora commits de release anteriores
    if [[ "$line" =~ ^release: ]]; then
        continue
    fi

    if [[ "$line" =~ ^feat(\(.+\))?: ]]; then
        FEAT_COMMITS+=("$line")
    elif [[ "$line" =~ ^fix(\(.+\))?: ]]; then
        FIX_COMMITS+=("$line")
    elif [[ "$line" =~ ^docs(\(.+\))?: ]]; then
        DOCS_COMMITS+=("$line")
    else
        OTHER_COMMITS+=("$line")
    fi
done < <(
    if [[ "$COMMIT_RANGE" == "HEAD" ]]; then
        git log --pretty=format:"%s" HEAD
    else
        git log --pretty=format:"%s" "$COMMIT_RANGE"
    fi
)

# Monta o bloco do changelog para esta versão
CHANGELOG_BLOCK="## [${NEW_VERSION}] - ${RELEASE_DATE}"
CHANGELOG_BLOCK+="\n"

HAS_CONTENT=false

if [[ ${#FEAT_COMMITS[@]} -gt 0 ]]; then
    CHANGELOG_BLOCK+="\n### Novidades\n"
    for commit in "${FEAT_COMMITS[@]}"; do
        CHANGELOG_BLOCK+="\n- ${commit}"
    done
    CHANGELOG_BLOCK+="\n"
    HAS_CONTENT=true
fi

if [[ ${#FIX_COMMITS[@]} -gt 0 ]]; then
    CHANGELOG_BLOCK+="\n### Correções\n"
    for commit in "${FIX_COMMITS[@]}"; do
        CHANGELOG_BLOCK+="\n- ${commit}"
    done
    CHANGELOG_BLOCK+="\n"
    HAS_CONTENT=true
fi

if [[ ${#DOCS_COMMITS[@]} -gt 0 ]]; then
    CHANGELOG_BLOCK+="\n### Documentação\n"
    for commit in "${DOCS_COMMITS[@]}"; do
        CHANGELOG_BLOCK+="\n- ${commit}"
    done
    CHANGELOG_BLOCK+="\n"
    HAS_CONTENT=true
fi

if [[ ${#OTHER_COMMITS[@]} -gt 0 ]]; then
    CHANGELOG_BLOCK+="\n### Outros\n"
    for commit in "${OTHER_COMMITS[@]}"; do
        CHANGELOG_BLOCK+="\n- ${commit}"
    done
    CHANGELOG_BLOCK+="\n"
    HAS_CONTENT=true
fi

if [[ "$HAS_CONTENT" == false ]]; then
    warn "Nenhum commit encontrado desde a última release."
    CHANGELOG_BLOCK+="\n_Sem alterações registradas._\n"
fi

# Link de comparação no GitHub
CHANGELOG_BLOCK+="\n**Diff completo:** [${COMPARE_FROM}...${TAG_NAME}](https://github.com/${GITHUB_REPO}/compare/${COMPARE_FROM}...${TAG_NAME})\n"

ok "Changelog gerado"

# =============================================================================
# Cria branch de release
# =============================================================================

info "Criando branch ${RELEASE_BRANCH}..."
git checkout -b "$RELEASE_BRANCH" --quiet
ok "Branch '${RELEASE_BRANCH}' criado"

# =============================================================================
# Atualiza VERSION
# =============================================================================

info "Atualizando VERSION para ${NEW_VERSION}..."
echo "$NEW_VERSION" > "$VERSION_FILE"
ok "VERSION atualizado"

# =============================================================================
# Atualiza CHANGELOG.md
# =============================================================================

info "Atualizando CHANGELOG.md..."

HEADER="# Changelog

Todas as alterações relevantes deste projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).
"

if [[ -f "$CHANGELOG_FILE" ]]; then
    # Insere o novo bloco após o header (linha 5 — após o header e a linha em branco)
    EXISTING_CONTENT="$(cat "$CHANGELOG_FILE")"
    # Remove o header existente (primeiras 5 linhas) e prepende o novo bloco
    BODY="$(echo "$EXISTING_CONTENT" | sed '1,/^$/{ /^# Changelog/d; /^$/d; /^Todas as/d; /^O formato/d; /^e este projeto/d; }')"
    {
        echo "$HEADER"
        echo -e "$CHANGELOG_BLOCK"
        echo "$BODY"
    } > "$CHANGELOG_FILE"
else
    # Cria o CHANGELOG.md do zero
    {
        echo "$HEADER"
        echo -e "$CHANGELOG_BLOCK"
    } > "$CHANGELOG_FILE"
fi

ok "CHANGELOG.md atualizado"

# =============================================================================
# Commit e tag
# =============================================================================

info "Criando commit e tag..."

git add "$VERSION_FILE" "$CHANGELOG_FILE"
git commit --quiet -m "release: ${TAG_NAME}"

# Mensagem da tag anotada = changelog desta versão (sem markdown excessivo)
TAG_MESSAGE="$(echo -e "$CHANGELOG_BLOCK" | sed 's/^##//' | sed 's/^###//' | sed '/^\*\*Diff/d')"
git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"

ok "Commit criado: release: ${TAG_NAME}"
ok "Tag anotada criada: ${TAG_NAME}"

# =============================================================================
# Cria Pull Request
# =============================================================================

info "Preparando Pull Request..."

# Primeiro precisa fazer push do branch
info "Fazendo push do branch ${RELEASE_BRANCH}..."
git push -u origin "$RELEASE_BRANCH" --quiet 2>/dev/null || {
    warn "Não foi possível fazer push automático do branch."
    warn "Faça manualmente: git push -u origin ${RELEASE_BRANCH}"
}

# Corpo do PR = changelog desta versão
PR_BODY="$(echo -e "$CHANGELOG_BLOCK")"

info "Criando PR no GitHub..."
PR_URL="$(gh pr create \
    --base main \
    --head "$RELEASE_BRANCH" \
    --title "release: ${TAG_NAME}" \
    --body "$PR_BODY" 2>/dev/null || echo "")"

if [[ -n "$PR_URL" ]]; then
    ok "Pull Request criado: ${PR_URL}"
else
    warn "Não foi possível criar o PR automaticamente."
    warn "Crie manualmente após o push do branch."
fi

# =============================================================================
# Resumo final
# =============================================================================

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Release ${TAG_NAME} preparada com sucesso  ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BOLD}Resumo:${NC}"
echo "  Versão:    ${CURRENT_VERSION} → ${NEW_VERSION}"
echo "  Branch:    ${RELEASE_BRANCH}"
echo "  Tag:       ${TAG_NAME}"
echo "  Changelog: ${CHANGELOG_FILE}"
if [[ -n "${PR_URL:-}" ]]; then
    echo "  PR:        ${PR_URL}"
fi
echo ""
echo -e "${BOLD}Próximos passos:${NC}"
echo ""
echo "  1. Revise o PR e faça merge no main"
echo ""
echo "  2. Após o merge, publique a release:"
echo -e "     ${YELLOW}./scripts/post-release.sh ${TAG_NAME}${NC}"
echo ""
