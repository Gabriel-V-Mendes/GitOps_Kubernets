# Runbook: Recuperação do Cluster Kind

## Cenário
O cluster Kind parou de funcionar ou foi destruído (ex: após reboot).

## Passos de Recuperação

### 1. Verificar se o Docker está rodando
```bash
docker ps
# Se não estiver rodando:
sudo systemctl start docker
```

### 2. Verificar clusters Kind existentes
```bash
kind get clusters
```

### 3. Se o cluster não existe, recriar
```bash
kind create cluster --config infrastructure/kind/kind-config.yaml
```

### 4. Recriar o namespace dev
```bash
kubectl create namespace dev
```

### 5. Reinstalar o Ingress Controller
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=NodePort
```

### 6. Reinstalar o ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts
```

### 7. Reaplicar a Application do ArgoCD
```bash
kubectl apply -f manifests/argocd/application.yaml
```

### 8. Validação
```bash
kubectl get pods -n argocd       # Todos Running?
kubectl get application -n argocd # Synced + Healthy?
kubectl get all -n dev            # Pods da app rodando?
```
