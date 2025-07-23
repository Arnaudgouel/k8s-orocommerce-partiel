{{- define "websocket.name" -}}
ws
{{- end -}}

{{- define "websocket.fullname" -}}
{{ include "websocket.name" . }}-{{ .Release.Name }}
{{- end -}}

{{- define "websocket.labels" -}}
helm.sh/chart: {{ include "websocket.chart" . }}
{{ include "websocket.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "websocket.selectorLabels" -}}
app.kubernetes.io/name: {{ include "websocket.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "websocket.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}} 