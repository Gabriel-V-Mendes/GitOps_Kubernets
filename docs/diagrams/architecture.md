# Diagrama de Arquitetura - GitOps Lab

## Visão Geral do Fluxo

```
┌─────────────────────────────────────────────────────────────────┐
│                        DEVELOPER MACHINE                        │
│                                                                 │
│  ┌──────────┐    git push     ┌──────────────────┐             │
│  │ VS Code  │ ──────────────► │ GitHub Repository │             │
│  │ (IDE)    │                 │ GitOps_Kubernets  │             │
│  └──────────┘                 └────────┬─────────┘             │
│                                        │                        │
│  ┌─────────────────────────────────────┼───────────────────┐   │
│  │              KIND CLUSTER           │                    │   │
│  │                                     │ monitora (Pull)    │   │
│  │  ┌──────────────┐    sync     ┌─────▼──────┐           │   │
│  │  │ Namespace:   │ ◄────────── │  ArgoCD    │           │   │
│  │  │ dev          │             │  (argocd)  │           │   │
│  │  │              │             └────────────┘           │   │
│  │  │ ┌──────────┐ │                                      │   │
│  │  │ │Deployment│ │     ┌─────────────────┐              │   │
│  │  │ │ (2 pods) │ │     │ Ingress NGINX   │              │   │
│  │  │ └──────────┘ │     │ (ingress-nginx) │              │   │
│  │  │ ┌──────────┐ │     └───────┬─────────┘              │   │
│  │  │ │ Service  │◄├─────────────┘                         │   │
│  │  │ │ClusterIP │ │   app.local:80                        │   │
│  │  │ └──────────┘ │                                      │   │
│  │  │ ┌──────────┐ │                                      │   │
│  │  │ │ Ingress  │ │                                      │   │
│  │  │ └──────────┘ │                                      │   │
│  │  └──────────────┘                                      │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Browser ──► http://app.local ──► Ingress ──► Service ──► Pods │
└─────────────────────────────────────────────────────────────────┘
```

## Ferramentas por Camada

| Camada           | Ferramenta       | Função                          |
|-----------------|------------------|---------------------------------|
| Cluster         | Kind             | Kubernetes local em Docker      |
| Empacotamento   | Helm             | Templates parametrizáveis       |
| Ambientes       | Kustomize        | Overlays por ambiente           |
| GitOps          | ArgoCD           | Sync automático Git → Cluster   |
| Ingress         | NGINX Controller | Roteamento HTTP externo         |
| CI/CD           | GitHub Actions   | Build, test e push de imagens   |
