{{/*
Expand the name of the chart.
*/}}
{{- define "wildfly-common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wildfly-common.fullName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
wildfly-common.appImageName is the name of the application image that is built/deployed
*/}}
{{- define "wildfly-common.appImageName" -}}
{{ default (include "wildfly-common.appName" .) .Values.image.name }}
{{- end -}}

{{/*
wildfly-common.appImage is the name:tag of the application image of of the application image that is built/deployed
*/}}
{{- define "wildfly-common.appImage" -}}
{{ include "wildfly-common.appImageName" . }}:{{ .Values.image.tag}}
{{- end -}}

{{/*
wildfly.appBuilderImageName corresponds to the name of the application Builder image
*/}}
{{- define "wildfly-common.appBuilderImageName" -}}
{{- if .Values.build.s2i.buildApplicationImage -}}
{{ include "wildfly-common.appImageName" . }}-build-artifacts
{{- else -}}
{{ include "wildfly-common.appImageName" . }}
{{- end -}}
{{- end -}}

{{/*
wildfly.appBuilderImage is the name:tag of the application Builder image
*/}}
{{- define "wildfly-common.appBuilderImage" -}}
{{ include "wildfly-common.appBuilderImageName" . }}:{{ .Values.image.tag}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wildfly-common.appName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wildfly-common.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Trigger a build from GitHub Webhook
*/}}
{{- define "wildfly-common.buildconfig.triggers.github" -}}
{{- if .Values.build.triggers.githubSecret}}
{{- include "wildfly-common.secret.lookup" (list .Release.Namespace .Values.build.triggers.githubSecret "Secret '%s' for GitHub webhook does not exist.") -}}
- type: "GitHub"
  github:
    secretReference:
      name: {{ quote .Values.build.triggers.githubSecret }}
{{ end }}
{{- end }}

{{/*
Trigger a build from Generic Webhook
*/}}
{{- define "wildfly-common.buildconfig.triggers.generic" -}}
{{- if .Values.build.triggers.genericSecret}}
{{- include "wildfly-common.secret.lookup" (list .Release.Namespace .Values.build.triggers.genericSecret "Secret '%s' for Generic webhook does not exist.") -}}
- type: "Generic"
  generic:
    secretReference:
      name: {{ quote .Values.build.triggers.genericSecret }}
    allowEnv: true
{{ end }}
{{- end }}

{{/*
Image pull secret to build the application image
*/}}
{{- define "wildfly-common.buildconfig.pullSecret" -}}
{{- if .Values.build.pullSecret}}
{{- include "wildfly-common.secret.lookup" (list .Release.Namespace .Values.build.pullSecret "Secret '%s' to pull images does not exist.") -}}
pullSecret:
  name: {{ .Values.build.pullSecret }}
{{ end }}
{{- end }}

{{/*
Source secret to pull the source code from a private Git repository
*/}}
{{- define "wildfly-common.buildconfig.sourceSecret" -}}
{{- if .Values.build.sourceSecret}}
{{- include "wildfly-common.secret.lookup" (list .Release.Namespace .Values.build.sourceSecret "Secret '%s' to pull the Git repository does not exist.") -}}
sourceSecret:
  name: {{ .Values.build.sourceSecret }}
{{ end }}
{{- end }}

{{/*
Image push secret to push the application image
*/}}
{{- define "wildfly-common.buildconfig.pushSecret" -}}
{{- if and .Values.build.output.pushSecret (eq .Values.build.output.kind "DockerImage") -}}
{{- include "wildfly-common.secret.lookup" (list .Release.Namespace .Values.build.output.pushSecret "Secret '%s' to push the application image does not exist.") -}}
pushSecret:
  name: {{ .Values.build.output.pushSecret }}
{{ end }}
{{- end }}


{{/*
Image pull secrets to pull the application image during deployment.
*/}}
{{- define "wildfly-common.deployment.imagePullSecrets" -}}
{{- if .Values.deploy.imagePullSecrets -}}
{{- range .Values.deploy.imagePullSecrets }}
  {{- include "wildfly-common.secret.lookup" (list $.Release.Namespace .name "Secret '%s' to pull the application image does not exist.") -}}
{{- end }}
imagePullSecrets:
  {{- tpl (toYaml .Values.deploy.imagePullSecrets) . | nindent 2 }}
{{ end }}
{{- end }}


{{/*
Verify that a secret exists in the given namespace or fail with an error message

This template needs 3 parameters in a list:
1. The namespace of the secret
2. the name of the secret
3. the error message if the secret does not exist

*/}}
{{- define "wildfly-common.secret.lookup" -}}
{{- $namespace := index . 0 -}}
{{- $secret := index . 1 -}}
{{- $failMessage := index . 2 -}}
{{- if not (lookup "v1" "Secret" $namespace $secret) -}}
{{- fail (printf $failMessage $secret) -}}
{{- end }}
{{- end }}