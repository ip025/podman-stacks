{{/* Common name/label helpers. */}}

{{- define "splitpro.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "splitpro.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "splitpro.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "splitpro.selectorLabels" -}}
app.kubernetes.io/name: {{ include "splitpro.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "splitpro.labels" -}}
helm.sh/chart: {{ include "splitpro.chart" . }}
{{ include "splitpro.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "splitpro.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{/*
Build DATABASE_URL. The password is intentionally not interpolated here; it is
resolved at container runtime from POSTGRES_PASSWORD via Kubernetes' $(VAR)
expansion, so the secret never appears in rendered manifests.
*/}}
{{- define "splitpro.databaseUrl" -}}
{{- $db := .Values.externalDatabase -}}
{{- $query := "" -}}
{{- if $db.parameters -}}
{{- $pairs := list -}}
{{- range $key, $value := $db.parameters -}}
{{- $pairs = append $pairs (printf "%s=%s" $key $value) -}}
{{- end -}}
{{- $query = printf "?%s" (join "&" $pairs) -}}
{{- end -}}
{{- printf "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DB)%s" $query -}}
{{- end -}}

{{- define "splitpro.secretName" -}}
{{- required "existingSecret is required: create a Secret and set .Values.existingSecret" .Values.existingSecret -}}
{{- end -}}

{{- define "splitpro.uploadsClaimName" -}}
{{- default (include "splitpro.fullname" .) .Values.persistence.uploads.existingClaim -}}
{{- end -}}
