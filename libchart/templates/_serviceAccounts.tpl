{{- define "libchart.serviceAccounts" }}
{{- range .Values.serviceAccounts }}
apiVersion: v1
kind: ServiceAccount
{{- if .irsaRoleArn }}
automountServiceAccountToken: true
{{- end }}
metadata:
  name: {{ .name }}
  {{- if .irsaRoleArn }}
  annotations:
    eks.amazonaws.com/role-arn: {{ .irsaRoleArn }}
  {{- end }}
---
{{- end }}
{{- end }}
