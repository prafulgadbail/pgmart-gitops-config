{{/* Labels on every resource: who it belongs to and which version runs */}}
{{- define "pgmart-service.labels" -}}
{{ include "pgmart-service.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/part-of: pgmart
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Labels that never change: the Deployment, Service and PDB find the pods by these */}}
{{- define "pgmart-service.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- end -}}
