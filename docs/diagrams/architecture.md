# Diagrama de Arquitetura — GitOps com Kubernetes e ArgoCD

## 1. Fluxo Ponta a Ponta (2 Repositórios: Código vs Manifests)

```mermaid
flowchart TB
    subgraph RepoApp["Repositório 1: Código da API (Projeto 1)"]
        direction TB
        PushCode["git push (FastAPI + PostgreSQL)"] --> AppCI["GitHub Actions: Lint, Pytest, Gitleaks, Build, Trivy"]
        AppCI --> GHCR[("GHCR: ghcr.io/...:sha-<commit>")]
        AppCI --> OpenPR["Job gitops-pr: Abre Pull Request com a nova tag"]
    end

    subgraph RepoGitOps["Repositório 2: Manifests GitOps (Projeto 3)"]
        direction TB
        OpenPR --> PR["Pull Request: atualiza tag em values-dev.yaml"]
        PR --> GitOpsCI["CI Manifests: Helm Lint + Kubeconform + Gitleaks"]
        GitOpsCI --> MergeMain["Merge na main (Estado Desejado no Git)"]
    end

    subgraph KindCluster["Cluster Kubernetes Local (Kind: devops-lab)"]
        direction TB
        MergeMain -. "Pull / Reconciliação Contínua (selfHeal + prune)" .-> ArgoCD["ArgoCD (namespace: argocd)"]

        subgraph Infra["Camada de Plataforma"]
            EG["Envoy Gateway (Gateway API)\nNodePort 30080 <- localhost:8080"]
            ESO["External Secrets Operator\nClusterSecretStore <- SOPS + age"]
        end

        subgraph DevNS["Namespace: dev (1 réplica)"]
            RouteDev["HTTPRoute: dev.api.local"]
            ESDev["ExternalSecret -> Secret (DATABASE_URL)"]
            ApiDev["Deployment: devops-api-dev\nUID 10001 | /health & /health/ready"]
            DbDev[("StatefulSet: postgres:17-alpine\nPVC 1Gi")]
            RouteDev --> ApiDev --> DbDev
            ESDev -.-> ApiDev & DbDev
        end

        subgraph StgNS["Namespace: staging (2 réplicas)"]
            RouteStg["HTTPRoute: staging.api.local"]
            ESStg["ExternalSecret -> Secret (DATABASE_URL)"]
            ApiStg["Deployment: devops-api-staging\nUID 10001 | /health & /health/ready"]
            DbStg[("StatefulSet: postgres:17-alpine\nPVC 2Gi")]
            RouteStg --> ApiStg --> DbStg
            ESStg -.-> ApiStg & DbStg
        end

        ArgoCD ==>|Sync| DevNS
        ArgoCD ==>|Sync| StgNS
        EG --> RouteDev & RouteStg
        ESO --> ESDev & ESStg
    end
```

## 2. Componentes por Camada

| Camada | Componente | Papel na Arquitetura |
|---|---|---|
| **Cluster Local** | `kind` (`devops-lab`) | Cluster Kubernetes em Docker com `extraPortMappings` (`127.0.0.1:8080 -> 30080`) |
| **GitOps Controller** | **ArgoCD** | Reconciliação contínua (modelo Pull) com `automated.selfHeal: true` e `prune: true` |
| **Roteamento (Gateway API)** | **Envoy Gateway** (`gateway.networking.k8s.io/v1`) | Substitui o antigo Ingress NGINX; expõe `Gateway` compartilhado e `HTTPRoute` por ambiente |
| **Gestão de Segredos** | **SOPS (`age`) + External Secrets Operator** | Semente criptografada no Git com SOPS; `ExternalSecret` gera `DATABASE_URL` em `dev` e `staging` |
| **Empacotamento** | **Helm Chart próprio (`devops-api`)** | Empacota a API do Projeto 1 + PostgreSQL 17 StatefulSet (zero charts da Bitnami) |
| **Ambientes** | `values-dev.yaml` & `values-staging.yaml` | Isolamento de recursos, réplicas e hostnames entre `dev` e `staging` |
| **Progressive Delivery (Opcional)** | **Argo Rollouts** | Canary deployment opcional (`rollout.enabled: true`) com divisão de tráfego na `HTTPRoute` |
