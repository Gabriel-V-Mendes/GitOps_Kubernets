#!/usr/bin/env bash
# ==============================================================================
# Smoke Test Completo:
#   Etapa 1 -> Acesso via `kubectl port-forward`
#   Etapa 2 -> Acesso via Gateway API (`HTTPRoute` + Envoy Gateway em localhost:8080)
# ==============================================================================
set -euo pipefail

GATEWAY_PORT="${GATEWAY_PORT:-8080}"

echo "=================================================================="
echo "Etapa 1 · Teste via kubectl port-forward (namespace: dev)"
echo "=================================================================="
kubectl port-forward -n dev svc/devops-api-dev 18000:8000 >/tmp/pf-dev.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID >/dev/null 2>&1 || true' EXIT
sleep 2

echo -n "GET /health (port-forward):       "
curl -fsS http://127.0.0.1:18000/health && echo ""
echo -n "GET /health/ready (port-forward): "
curl -fsS http://127.0.0.1:18000/health/ready && echo ""

kill $PF_PID >/dev/null 2>&1 || true
trap - EXIT

echo ""
echo "=================================================================="
echo "Etapa 2 · Teste via Gateway API (localhost:${GATEWAY_PORT})"
echo "=================================================================="
for env_host in "dev:dev.api.local" "staging:staging.api.local"; do
  env_name="${env_host%%:*}"
  host_header="${env_host##*:}"
  echo "--- Ambiente: ${env_name} (Host: ${host_header}) ---"

  echo -n "  GET /health:       "
  curl -fsS -H "Host: ${host_header}" "http://127.0.0.1:${GATEWAY_PORT}/health" && echo ""

  echo -n "  GET /health/ready: "
  curl -fsS -H "Host: ${host_header}" "http://127.0.0.1:${GATEWAY_PORT}/health/ready" && echo ""

  echo -n "  POST /items:       "
  curl -fsS -H "Host: ${host_header}" -H "Content-Type: application/json" \
    -X POST "http://127.0.0.1:${GATEWAY_PORT}/items" \
    -d "{\"name\":\"gitops-${env_name}\",\"description\":\"Validado via Gateway API\"}" && echo ""

  echo -n "  GET /items:        "
  curl -fsS -H "Host: ${host_header}" "http://127.0.0.1:${GATEWAY_PORT}/items" && echo ""
done

echo ""
echo "✅ Todos os smoke tests (port-forward + Gateway API em dev e staging) passaram!"
