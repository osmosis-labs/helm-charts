{{/*
Expand the name of the chart.
*/}}
{{- define "osmosis-fullnode.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "osmosis-fullnode.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s%s" .Release.Name (.Values.global.nameSuffix | default "") | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s%s" .Release.Name $name (.Values.global.nameSuffix | default "") | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "osmosis-fullnode.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "osmosis-fullnode.labels" -}}
helm.sh/chart: {{ include "osmosis-fullnode.chart" . }}
{{ include "osmosis-fullnode.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.statefulset.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "osmosis-fullnode.selectorLabels" -}}
app.kubernetes.io/name: {{ include "osmosis-fullnode.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "osmosis-fullnode.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "osmosis-fullnode.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Pod selector for StatefulSet
*/}}
{{- define "osmosis-fullnode.podSelector" -}}
statefulset.kubernetes.io/pod-name: {{ include "osmosis-fullnode.fullname" . }}-0
{{- end }}

{{/*
Create osmosis environment variables
*/}}
{{- define "osmosis-fullnode.osmosisEnv" -}}
{{- range $key, $value := .Values.containers.osmosis.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Create droid environment variables
*/}}
{{- define "osmosis-fullnode.droidEnv" -}}
{{- range $key, $value := .Values.containers.droid.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Create tolerations from values
*/}}
{{- define "osmosis-fullnode.tolerations" -}}
{{- with .Values.statefulset.tolerations }}
tolerations:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Create affinity from values
*/}}
{{- define "osmosis-fullnode.affinity" -}}
{{- with .Values.statefulset.affinity }}
affinity:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Create nodeSelector from values
*/}}
{{- define "osmosis-fullnode.nodeSelector" -}}
{{- with .Values.statefulset.nodeSelector }}
nodeSelector:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Create monitoring annotations
*/}}
{{- define "osmosis-fullnode.monitoringAnnotations" -}}
{{- if .Values.monitoring.datadog.enabled }}
ad.datadoghq.com/osmosis.check_names: {{ .Values.monitoring.datadog.annotations.checkNames | quote }}
ad.datadoghq.com/osmosis.init_configs: {{ .Values.monitoring.datadog.annotations.initConfigs | quote }}
ad.datadoghq.com/osmosis.instances: {{ tpl .Values.monitoring.datadog.annotations.instances . | quote }}
{{- end }}
{{- end }} 
