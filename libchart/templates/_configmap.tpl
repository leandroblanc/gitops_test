{{- define "libchart.configmap" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  {{- range $key, $val := .Values.env.configmap }}
  {{ $key }}: {{ $val | quote }}
  {{- end}}
---
{{- end}}
