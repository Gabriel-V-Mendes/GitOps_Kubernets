#!/bin/bash
# Smoke Test - Valida se a aplicação está respondendo corretamente
# Uso: ./smoke-test.sh <URL>

set -e

URL="${1:-http://app.local}"
EXPECTED_STATUS=200

echo "🔍 Executando smoke test em: $URL"

STATUS=$(curl -sk -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" -eq "$EXPECTED_STATUS" ]; then
    echo "✅ Smoke test PASSED — HTTP $STATUS"
    exit 0
else
    echo "❌ Smoke test FAILED — Esperado: $EXPECTED_STATUS | Recebido: $STATUS"
    exit 1
fi
