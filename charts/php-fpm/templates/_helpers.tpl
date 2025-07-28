{{- define "phpfpm.name" -}}
php-fpm
{{- end -}}

{{- define "phpfpm.fullname" -}}
{{ include "phpfpm.name" . }}-{{ .Release.Name }}
{{- end -}} 

{{- define "phpfpm.labels" -}}
helm.sh/chart: {{ include "phpfpm.chart" . }}
{{ include "phpfpm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "phpfpm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "phpfpm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "phpfpm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}} 