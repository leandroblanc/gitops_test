{{- define "libchart.services" }}
{{- range .Values.services }}
# Define stable k8s service
apiVersion: v1
kind: Service
metadata:
  name: {{ .deploymentName }}
  {{- if .labels }}
  labels:
    {{ toYaml .labels | nindent 4 }}
  {{- end }}
  {{- if .annotations }}
  annotations:
    {{- toYaml .annotations | nindent 4 }}
  {{- end }}
spec:
  type: {{ .type | default "ClusterIP" }}
  ports:
    - port: {{ .port | default 80 }}
      targetPort: {{ .targetPort | default 80 }}
      protocol: TCP
      appProtocol: {{ .appProtocol }}
      name: {{ .appProtocol }}
  selector:
    app.kubernetes.io/name: {{ .deploymentName }}
---
{{- if $.Values.canary }}
# Create a canary service using the -canary suffix
apiVersion: v1
kind: Service
metadata:
  name: {{ .deploymentName }}-canary
  {{- if .labels }}
  labels:
    {{ toYaml .labels | nindent 4 }}
  {{- end }}
  {{- if .annotations }}
  annotations:
    {{- toYaml .annotations | nindent 4 }}
  {{- end }}
spec:
  type: {{ .type | default "ClusterIP" }}
  ports:
    - port: {{ .port | default 80 }}
      targetPort: {{ .targetPort | default 80 }}
      protocol: TCP
      appProtocol: {{ .appProtocol }}
      name: {{ .appProtocol }}
  selector:
    app.kubernetes.io/name: {{ .deploymentName }}
---
{{- end }}
# End range services
{{- end }}
# End define libchart
{{- end }}
