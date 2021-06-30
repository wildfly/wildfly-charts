{{/*
wildfly.builderImage corresponds to the name of the WildFly Builder Image
*/}}
{{- define "wildfly.builderImage" -}}
{{ .Values.build.s2i.builderImage }}
{{- end }}

{{/*
wildfly.runtimeImage corresponds to the name of the WildFly Runtime Image
*/}}
{{- define "wildfly.runtimeImage" -}}
{{ .Values.build.s2i.runtimeImage }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wildfly.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wildfly.labels" -}}
helm.sh/chart: {{ include "wildfly.chart" . }}
{{ include "wildfly-common.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "wildfly.metadata.labels" -}}
metadata:
  labels:
  {{- include "wildfly.labels" . | nindent 4 }}
{{- end -}}