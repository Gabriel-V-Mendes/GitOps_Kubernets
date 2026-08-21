# GitOps com Kubernetes

Projeto prático de estudo de **GitOps e Kubernetes**, cobrindo desde a criação de um cluster local até deploy automatizado com ArgoCD.

## O que foi exercitado

- **Kubernetes (Kind)** — Cluster local multi-node com Kind para simular um ambiente real
- **Manifests YAML** — Criação manual de Deployments, Services e Ingress (raw YAML)
- **Helm** — Gerenciamento de pacotes Kubernetes com templates, values por ambiente e chart próprio
- **Kustomize** — Overlays por ambiente (dev, staging, production) usando patches sobre uma base comum
- **Ingress Controller (NGINX)** — Roteamento de tráfego externo para os serviços internos do cluster
- **ArgoCD (GitOps)** — Deploy contínuo automatizado onde o Git é a única fonte de verdade
- **Network Policies** — Políticas de rede para controlar tráfego entre pods
- **CI/CD Pipeline** — Workflow GitHub Actions para build, test e deploy automatizado

## Estrutura do projeto

```
├── .github/workflows/          # Pipeline CI/CD (GitHub Actions)
├── app/                        # Aplicação (Dockerfile, código fonte, testes)
│   ├── src/                    # Código fonte da aplicação
│   └── tests/                  # Testes (smoke test)
├── manifests/
│   ├── base/                   # Manifests base (Kustomize)
│   ├── overlays/               # Overlays por ambiente (dev, staging, prod)
│   ├── helm/my-app/            # Helm Chart completo
│   └── argocd/                 # Manifesto Application do ArgoCD
├── infrastructure/
│   ├── kind/                   # Configuração do cluster Kind
│   ├── argocd/                 # Namespace e setup do ArgoCD
│   ├── ingress/                # Namespace do Ingress Controller
│   ├── monitoring/             # Namespace para monitoramento
│   ├── network-policies/       # Políticas de rede
│   └── rollouts/               # Namespace para Argo Rollouts
└── docs/                       # Documentação (ADRs, runbooks, diagramas)
```

## Stack utilizada

| Ferramenta | Função |
|------------|--------|
| Kind | Cluster Kubernetes local |
| Helm | Gerenciador de pacotes |
| Kustomize | Overlays por ambiente |
| ArgoCD | GitOps / Deploy contínuo |
| NGINX Ingress | Roteamento de tráfego |
| GitHub Actions | CI/CD Pipeline |

## Como rodar

```bash
# Criar o cluster
kind create cluster --config infrastructure/kind/kind-config.yaml

# Instalar Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Instalar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Aplicar manifesto GitOps
kubectl apply -f manifests/argocd/application.yaml
```
