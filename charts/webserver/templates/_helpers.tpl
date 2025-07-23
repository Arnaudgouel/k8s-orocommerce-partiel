{{- define "webserver.name" -}}
webserver
{{- end -}}

{{- define "webserver.fullname" -}}
{{ include "webserver.name" . }}-{{ .Release.Name }}
{{- end -}}
