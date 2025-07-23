{{- define "phpfpm.name" -}}
php-fpm
{{- end -}}

{{- define "phpfpm.fullname" -}}
{{ include "phpfpm.name" . }}-{{ .Release.Name }}
{{- end -}} 