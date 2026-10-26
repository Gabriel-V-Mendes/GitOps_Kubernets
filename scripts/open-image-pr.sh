#!/usr/bin/env bash
# ==============================================================================
# Abre um Pull Request atualizando a tag da imagem no repositório de manifests.
#
# Uso:
#   ./scripts/open-image-pr.sh <nova-tag> [dev|staging]
# Exemplo:
#   ./scripts/open-image-pr.sh sha-74f3e26566a1c1dc9033d18d9b6f2beddfc7eb8c dev
# ==============================================================================
set -euo pipefail

NEW_TAG="${1:?Informe a nova tag da imagem (ex.: sha-74f3e26...)}"
TARGET_ENV="${2:-dev}"
VALUES_FILE="manifests/helm/devops-api/values-${TARGET_ENV}.yaml"

if [ ! -f "$VALUES_FILE" ]; then
  echo "Erro: arquivo '$VALUES_FILE' não encontrado." >&2
  exit 1
fi

SHORT_TAG="${NEW_TAG:0:12}"
BRANCH="chore/image-${TARGET_ENV}-${SHORT_TAG}"

git checkout -b "$BRANCH"
sed -i -E "s|^([[:space:]]*tag:[[:space:]]*).*|\1\"${NEW_TAG}\"|" "$VALUES_FILE"

if git diff --quiet "$VALUES_FILE"; then
  echo "A tag '${NEW_TAG}' já está configurada em ${VALUES_FILE}."
  git checkout -
  git branch -D "$BRANCH"
  exit 0
fi

git add "$VALUES_FILE"
git commit -m "chore(${TARGET_ENV}): update devops-api image tag to ${NEW_TAG}"
git push -u origin "$BRANCH"

gh pr create \
  --title "chore(${TARGET_ENV}): bump devops-api image to ${SHORT_TAG}" \
  --body "Atualização automatizada da tag da imagem da API do Projeto 1 no ambiente **${TARGET_ENV}** para \`${NEW_TAG}\`." \
  --base main \
  --head "$BRANCH"
