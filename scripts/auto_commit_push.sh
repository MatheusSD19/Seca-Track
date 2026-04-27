#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   ./scripts/auto_commit_push.sh "mensagem do commit" [branch]
# Exemplo:
#   ./scripts/auto_commit_push.sh "feat: atualiza dashboard" work

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 \"mensagem do commit\" [branch]"
  exit 1
fi

MSG="$1"
TARGET_BRANCH="${2:-$(git rev-parse --abbrev-ref HEAD)}"

if [[ -z "$(git status --porcelain)" ]]; then
  echo "Sem alterações para commit."
  exit 0
fi

git add -A

git commit -m "$MSG"

echo "Commit criado com sucesso em $(git rev-parse --abbrev-ref HEAD)."

REMOTE_NAME="origin"
if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  echo "Remote '$REMOTE_NAME' não configurado. Commit ficou local."
  echo "Configure com: git remote add origin <URL_DO_REPOSITORIO>"
  exit 0
fi

# Tenta enviar para o branch solicitado
if git push "$REMOTE_NAME" "HEAD:$TARGET_BRANCH"; then
  echo "Push concluído para $REMOTE_NAME/$TARGET_BRANCH"
else
  echo "Falha no push. Tente autenticar e executar manualmente:"
  echo "git push $REMOTE_NAME HEAD:$TARGET_BRANCH"
  exit 1
fi
