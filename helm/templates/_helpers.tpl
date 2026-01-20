{{- define "argocd-renderer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "argocd-renderer.fullname" -}}
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

{{- define "argocd-renderer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "argocd-renderer.labels" -}}
helm.sh/chart: {{ include "argocd-renderer.chart" . }}
{{ include "argocd-renderer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "argocd-renderer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argocd-renderer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "argocd-renderer.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "argocd-renderer.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "argocd-renderer.renderApi.fullname" -}}
{{- printf "%s-api" (include "argocd-renderer.fullname" .) }}
{{- end }}

{{- define "argocd-renderer.renderApi.labels" -}}
{{ include "argocd-renderer.labels" . }}
app.kubernetes.io/component: api
{{- end }}

{{- define "argocd-renderer.renderApi.selectorLabels" -}}
{{ include "argocd-renderer.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{- define "argocd-renderer.renderWorker.fullname" -}}
{{- printf "%s-worker" (include "argocd-renderer.fullname" .) }}
{{- end }}

{{- define "argocd-renderer.renderWorker.labels" -}}
{{ include "argocd-renderer.labels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{- define "argocd-renderer.renderWorker.selectorLabels" -}}
{{ include "argocd-renderer.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{- define "argocd-renderer.redis.host" -}}
{{- if .Values.redis.host }}
{{- .Values.redis.host }}
{{- else }}
{{- printf "%s-redis-master" (include "argocd-renderer.fullname" .) }}
{{- end }}
{{- end }}

{{- define "argocd-renderer.redis.port" -}}
{{- default 6379 .Values.redis.port }}
{{- end }}

{{- define "argocd-renderer.repoServer.host" -}}
{{- if .Values.repoServer.host }}
{{- .Values.repoServer.host }}
{{- else }}
{{- printf "%s-argo-cd-repo-server" .Release.Name }}
{{- end }}
{{- end }}

{{- define "argocd-renderer.repoServer.port" -}}
{{- default 8081 .Values.repoServer.port }}
{{- end }}

{{- define "argocd-renderer.repoServer.url" -}}
{{- printf "%s:%d" (include "argocd-renderer.repoServer.host" .) (int (include "argocd-renderer.repoServer.port" .)) }}
{{- end }}

{{- define "argocd-renderer.renderApi.image" -}}
{{- $tag := .Values.renderApi.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.renderApi.image.repository $tag }}
{{- end }}

{{- define "argocd-renderer.renderWorker.image" -}}
{{- $tag := .Values.renderWorker.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.renderWorker.image.repository $tag }}
{{- end }}

{{- define "argocd-renderer.storage.pvcName" -}}
{{- if .Values.renderWorker.storage.pvc.claimName }}
{{- .Values.renderWorker.storage.pvc.claimName }}
{{- else }}
{{- printf "%s-artifacts" (include "argocd-renderer.fullname" .) }}
{{- end }}
{{- end }}
