#!/usr/bin/env bash
# ==============================================================================
# Demonstração Prática de Configuration Drift & Self-Heal no ArgoCD
#
# Altera manualmente o cluster (`kubectl scale` + `kubectl label`) no namespace `dev`
# e mostra o ArgoCD detectando o drift (`OutOfSync`) e restaurando automaticamente
# o estado declarado no Git (`selfHeal: true`).
# ==============================================================================
set -euo pipefail

NS="dev"
DEPLOY="devops-api-dev"
APP="devops-api-dev"

echo "=================================================================="
echo "1. Estado inicial (declarado no Git: replicas=1)"
echo "=================================================================="
kubectl get application "$APP" -n argocd -o wide
kubectl get deployment "$DEPLOY" -n "$NS"

echo ""
echo "=================================================================="
echo "2. Causando DRIFT manual no cluster (kubectl scale --replicas=4)"
echo "=================================================================="
kubectl scale deployment "$DEPLOY" -n "$NS" --replicas=4
kubectl annotate deployment "$DEPLOY" -n "$NS" drift.demo/manual-change="true" --overwrite

echo "Estado imediatamente após a alteração manual (drift introduzido):"
kubectl get deployment "$DEPLOY" -n "$NS"
kubectl get pods -n "$NS" -l app.kubernetes.io/instance=devops-api-dev,app.kubernetes.io/component=api

# Solicita refresh imediato na Application para não precisar esperar o polling de 3 min
kubectl annotate application "$APP" -n argocd argocd.argoproj.io/refresh="normal" --overwrite >/dev/null

echo ""
echo "=================================================================="
echo "3. Aguardando o ArgoCD (selfHeal: true) corrigir o drift..."
echo "=================================================================="
for attempt in $(seq 1 30); do
  replicas=$(kubectl get deployment "$DEPLOY" -n "$NS" -o jsonpath='{.spec.replicas}')
  sync_status=$(kubectl get application "$APP" -n argocd -o jsonpath='{.status.sync.status}')
  echo "[${attempt}s] Application sync=$sync_status | Deployment spec.replicas=$replicas"
  if [ "$replicas" = "1" ] && [ "$sync_status" = "Synced" ]; then
    echo ""
    echo "✅ Drift corrigido automaticamente pelo ArgoCD!"
    break
  fi
  sleep 2
done

echo ""
echo "=================================================================="
echo "4. Estado final restaurado (idêntico ao Git: replicas=1)"
echo "=================================================================="
kubectl get application "$APP" -n argocd -o wide
kubectl get deployment "$DEPLOY" -n "$NS"
kubectl get pods -n "$NS" -l app.kubernetes.io/instance=devops-api-dev,app.kubernetes.io/component=api
