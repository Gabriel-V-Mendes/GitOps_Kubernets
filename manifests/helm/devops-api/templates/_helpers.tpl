{{/*
Nome base do chart.
*/}}
{{- define "devops-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Nome completo qualificado (evita duplicação se o Release.Name já contiver o nome do chart).
*/}}
{{- define "devops-api.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Nome do Secret de banco de dados (gerado pelo ExternalSecret ou informado via existingSecret).
*/}}
{{- define "devops-api.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret }}
{{- else }}
{{- printf "%s-db-secret" (include "devops-api.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Labels comuns da API.
*/}}
{{- define "devops-api.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "devops-api.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Labels comuns do PostgreSQL.
*/}}
{{- define "devops-api.postgresLabels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "devops-api.postgresSelectorLabels" . }}
app.kubernetes.io/version: "17-alpine"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels da API.
*/}}
{{- define "devops-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "devops-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: api
{{- end }}

{{/*
Selector labels do PostgreSQL.
*/}}
{{- define "devops-api.postgresSelectorLabels" -}}
app.kubernetes.io/name: {{ include "devops-api.name" . }}-postgres
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end }}
