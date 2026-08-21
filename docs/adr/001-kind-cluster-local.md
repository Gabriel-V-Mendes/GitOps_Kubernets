# ADR-001: Escolha do Kind como Cluster Local

## Status
Aceito

## Contexto
Precisávamos de um cluster Kubernetes local para desenvolvimento e aprendizado GitOps.
Alternativas consideradas: Minikube, K3s, MicroK8s, Kind.

## Decisão
Escolhemos o **Kind** (Kubernetes IN Docker) porque:
- Roda nativamente em containers Docker (sem VM)
- Suporta multi-node para simular produção
- Configuração declarativa via YAML
- Suporte nativo a port mapping (extraPortMappings)
- Amplamente usado em CI/CD para testes

## Consequências
- Requer Docker instalado
- Cluster não persiste após reboot (recriável via `kind create cluster`)
- Performance limitada pelo hardware local
