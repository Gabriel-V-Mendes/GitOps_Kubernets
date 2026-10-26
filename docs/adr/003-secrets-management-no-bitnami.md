# ADR-003: Gestão de Segredos (SOPS + External Secrets) e Remoção de Charts da Bitnami

## Status
Aceito

## Contexto
Em GitOps, o repositório Git é a única fonte de verdade do cluster, mas **segredos nunca podem ir ao Git em texto puro ou apenas codificados em Base64** (`kind: Secret`). Além disso, precisamos **evitar charts da Bitnami** (tanto para banco de dados quanto para controladores), pois a Bitnami restringiu o catálogo gratuito de imagens e adiciona complexidade e dependências opacas.

## Alternativas Avaliadas para Segredos

| Solução | Como funciona | Prós | Contras |
|---|---|---|---|
| **External Secrets Operator (ESO)** | Controlador CNCF que lê um cofre externo (Vault, AWS SM, GCP SM ou K8s Store) via `ExternalSecret` e cria o `Secret` nativo no cluster | Padrão de mercado em produção; suporta `template` para montar `DATABASE_URL` dinamicamente; zero vínculo com Bitnami | Precisa de um Secret/cofre inicial ("secret zero") |
| **Mozilla SOPS + age** | Criptografa apenas os valores (`data`/`stringData`) do YAML com chave pública `age` (`AES-256-GCM`); a chave privada fica fora do Git | Simples, auditável no Git (`git diff` mostra qual chave mudou), sem controlador extra para o arquivo em si | Exige descriptografia no bootstrap ou plugin KSOPS no ArgoCD |
| **Sealed Secrets** | Criptografa Secrets com a chave pública do controlador no cluster (`kubeseal`) | Fácil para um único cluster | Mantido pela Bitnami (`bitnami-labs`); o segredo criptografado fica preso à chave daquele cluster específico (dificulta recriação limpa do cluster se a chave não for backupeada) |

## Decisão
1. **Combinamos SOPS (`age`) + External Secrets Operator (ESO):**
   - O "Secret Zero" (`infrastructure/secrets/postgres-source-secret.sops.yaml`) fica versionado no Git **criptografado com SOPS + age** (`ENC[AES256_GCM,...]`). A chave privada `.sops-age-key.txt` está no `.gitignore` e nunca vai ao Git.
   - No bootstrap do cluster, o SOPS descriptografa essa semente em memória (`sops -d ... | kubectl apply -f -`) no namespace isolado `external-secrets`.
   - O **External Secrets Operator** (instalado do repositório oficial `https://charts.external-secrets.io`) usa um `ClusterSecretStore` para ler essa semente e reconciliar os objetos `ExternalSecret` que o ArgoCD aplica nos namespaces `dev` e `staging`.
   - O Helm chart da aplicação (`manifests/helm/devops-api`) **não possui `templates/secret.yaml`**: ele declara apenas `templates/externalsecret.yaml`.
2. **PostgreSQL próprio no Helm Chart (Zero Bitnami):**
   - Em vez de depender de `bitnami/postgresql`, criamos `templates/postgres-statefulset.yaml` e `templates/postgres-service.yaml` usando a imagem oficial `postgres:17-alpine` fixada por digest (`sha256:b0f9560a...`), idêntica à do Projeto 1, com `livenessProbe`/`readinessProbe` (`pg_isready`), `resources` (`requests`/`limits`) e `PersistentVolumeClaim`.

## Consequências
- O CI bloqueia qualquer PR que tente introduzir `kind: Secret` em `manifests/` ou que falhe no scan do **Gitleaks**.
- Ao apagar o cluster (`kind delete cluster`) e rodar `./scripts/bootstrap.sh`, os segredos de `dev` e `staging` são restaurados automaticamente sem intervenção manual.
