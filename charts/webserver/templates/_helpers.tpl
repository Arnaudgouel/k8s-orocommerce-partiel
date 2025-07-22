{{- define "orocommerce.name" -}}
orocommerce
{{- end -}}

{{- define "orocommerce.fullname" -}}
{{ include "orocommerce.name" . }}-{{ .Release.Name }}
{{- end -}}
