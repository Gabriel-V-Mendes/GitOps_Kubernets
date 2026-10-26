#!/usr/bin/env bash
# ==============================================================================
# Demonstração do Desafio Opcional: Argo Rollouts Canary + Gateway API
#
# Prova prática de entrega progressiva (Canary) no ambiente `staging` com
# divisão real de tráfego via Gateway API (`gateway.networking.k8s.io/v1`).
# O plugin `argoproj-labs/gatewayAPI` manipula dinamicamente os pesos (`weight`)
# dos `backendRefs` na `HTTPRoute` (`devops-api-staging-route`):
#   100/0 (estável) -> 80/20 (canário 20%) -> 50/50 (canário 50%) -> 100/0 (promovido)
# ==============================================================================
set -euo pipefail

NAMESPACE="staging"
ROLLOUT="devops-api-staging"
HTTPROUTE="devops-api-staging-route"
NEW_REV="canary-$(date +%s)"

print_weights() {
  kubectl get httproute "$HTTPROUTE" -n "$NAMESPACE" \
    -o jsonpath='{range .spec.rules[0].backendRefs[*]}{.name}={.weight}% {end}{"\n"}'
}

echo "=================================================================="
echo "1. Estado inicial do Rollout e pesos na HTTPRoute ($NAMESPACE)"
echo "=================================================================="
kubectl get rollout.argoproj.io "$ROLLOUT" -n "$NAMESPACE"
echo -n "Pesos atuais na HTTPRoute: "
print_weights

echo ""
echo "=================================================================="
echo "2. Disparando nova revisão Canário no Rollout (APP_VERSION=$NEW_REV)"
echo "=================================================================="
# Desabilita temporariamente o auto-sync do ArgoCD em staging apenas durante a
# observação dos passos canário (20% -> 50% -> 100%), reabilitando ao final.
kubectl patch application devops-api-staging -n argocd --type merge \
  -p '{"spec":{"syncPolicy":{"automated":null}}}' >/dev/null

kubectl patch rollout.argoproj.io "$ROLLOUT" -n "$NAMESPACE" --type json \
  -p="[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/env/2/value\",\"value\":\"${NEW_REV}\"}]"

echo ""
echo "=================================================================="
echo "3. Acompanhando a progressão Canário e os pesos da Gateway API"
echo "=================================================================="
SEEN_20=0
SEEN_50=0
for i in $(seq 1 60); do
  WEIGHTS="$(print_weights)"
  STATUS="$(kubectl get rollout.argoproj.io "$ROLLOUT" -n "$NAMESPACE" -o jsonpath='{.status.phase} (step {.status.currentStepIndex})')"
  echo "[${i}s] Rollout: ${STATUS} | HTTPRoute weights: ${WEIGHTS}"

  if [[ "$WEIGHTS" == *"=20%"* ]]; then
    SEEN_20=1
  fi
  if [[ "$WEIGHTS" == *"=50%"* ]]; then
    SEEN_50=1
  fi
  if [[ "$SEEN_20" -eq 1 && "$SEEN_50" -eq 1 && "$WEIGHTS" == *"devops-api-staging=100% devops-api-staging-canary=0%"* ]]; then
    echo ""
    echo "✅ Promoção Canário (20% -> 50% -> 100%) concluída com sucesso!"
    break
  fi
  sleep 2
done

echo ""
echo "=================================================================="
echo "4. Reabilitando auto-sync + selfHeal do ArgoCD em staging"
echo "=================================================================="
kubectl patch application devops-api-staging -n argocd --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}' >/dev/null

kubectl get rollout.argoproj.io "$ROLLOUT" -n "$NAMESPACE"
echo -n "Pesos finais na HTTPRoute: "
print_weights
