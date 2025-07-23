{{- define "database.name" -}}
database
{{- end -}}

{{- define "database.fullname" -}}
{{ include "database.name" . }}-{{ .Release.Name }}
{{- end -}}