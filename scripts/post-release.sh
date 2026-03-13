#!/usr/bin/env bash
# =============================================================================
# post-release.sh — Publica uma release no GitHub
#
# Rode após o merge do PR de release no main.
#
# Uso:
#   ./scripts/post-release.sh v0.2.0
#
# O que faz:
#   1. Volta para main e puxa as alterações do merge
#   2. Faz push da tag para o GitHub
#   3. Extrai as notas da versão do CHANGELOG.md
#   4. Cria uma GitHub Release com as notas
# =============================================================================
set -euo pipefail

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
fatal() { echo -e "${RED}[erro]${NC}  $*" >&2; exit 1; }

# --- Constantes ---
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG_FILE="$REPO_ROOT/CHANGELOG.md"

# =============================================================================
# Validações
# =============================================================================

TAG_NAME="${1:-}"
if [[ -z "$TAG_NAME" ]]; then
    echo -e "${BOLD}Uso:${NC} $0 <tag>"
    echo ""
    echo "  Exemplo: $0 v0.2.0"
    echo ""
    echo -e "  Tags disponíveis:"
    git tag --sort=-version:refname | head -5 | sed 's/^/    /'
    exit 1
fi

# Garante formato v*
if [[ ! "$TAG_NAME" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fatal "Formato de tag inválido: '$TAG_NAME'. Esperado: vX.Y.Z"
fi

# Verifica dependências
if ! command -v gh &>/dev/null; then
    fatal "GitHub CLI (gh) não encontrado. Instale: https://cli.github.com/"
fi

if ! gh auth status &>/dev/null; then
    fatal "gh CLI não está autenticado. Rode: gh auth login"
fi

# Verifica se a tag existe localmente
if ! git rev-parse "$TAG_NAME" &>/dev/null; then
    fatal "Tag '$TAG_NAME' não encontrada localmente."
fi

# Verifica se já existe uma release no GitHub para esta tag
if gh release view "$TAG_NAME" &>/dev/null; then
    fatal "GitHub Release '${TAG_NAME}' já existe."
fi

ok "Validações passaram"
echo ""

# =============================================================================
# Volta para main e atualiza
# =============================================================================

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$CURRENT_BRANCH" != "main" ]]; then
    info "Voltando para main..."
    git checkout main --quiet
fi

info "Atualizando main..."
git pull --quiet origin main
ok "main atualizado"

# =============================================================================
# Push da tag
# =============================================================================

info "Fazendo push da tag ${TAG_NAME}..."
git push origin "$TAG_NAME"
ok "Tag ${TAG_NAME} publicada no GitHub"

# =============================================================================
# Extrai notas do CHANGELOG.md
# =============================================================================

VERSION="${TAG_NAME#v}"  # remove o prefixo 'v'

info "Extraindo notas da versão ${VERSION} do CHANGELOG.md..."

# Extrai o bloco entre "## [VERSION]" e o próximo "## [" (ou fim do arquivo)
RELEASE_NOTES="$(awk -v ver="$VERSION" '
    /^## \[/ {
        if (found) exit
        if (index($0, "[" ver "]")) found=1
    }
    found { print }
' "$CHANGELOG_FILE")"

if [[ -z "$RELEASE_NOTES" ]]; then
    warn "Notas não encontradas no CHANGELOG.md para ${VERSION}."
    RELEASE_NOTES="Release ${TAG_NAME}"
fi

ok "Notas extraídas"

# =============================================================================
# Cria GitHub Release
# =============================================================================

info "Criando GitHub Release..."

RELEASE_URL="$(gh release create "$TAG_NAME" \
    --title "$TAG_NAME" \
    --notes "$RELEASE_NOTES")"

ok "GitHub Release criada: ${RELEASE_URL}"

# =============================================================================
# Limpeza: remove branch de release (local e remoto)
# =============================================================================

RELEASE_BRANCH="release/${TAG_NAME}"

if git rev-parse --verify "$RELEASE_BRANCH" &>/dev/null; then
    info "Removendo branch local ${RELEASE_BRANCH}..."
    git branch -d "$RELEASE_BRANCH" --quiet 2>/dev/null || true
fi

if git ls-remote --heads origin "$RELEASE_BRANCH" | grep -q .; then
    info "Removendo branch remoto ${RELEASE_BRANCH}..."
    git push origin --delete "$RELEASE_BRANCH" --quiet 2>/dev/null || true
fi

ok "Branch de release removido"

# =============================================================================
# Resumo
# =============================================================================

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Release ${TAG_NAME} publicada!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  GitHub Release: ${RELEASE_URL}"
echo -e "  Tag:            ${TAG_NAME}"
echo ""
