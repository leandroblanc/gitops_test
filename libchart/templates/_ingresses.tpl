{{- define "libchart.ingresses" }}
{{- range .Values.ingresses }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .name }}
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    kubernetes.io/tls-acme: "true"
{{- if .annotations }}
{{ toYaml .annotations | indent 4 }}
{{- end }}
spec:
  ingressClassName: {{ .ingressClassName | default "nginx" | quote }}
  tls:
    {{- range .rules }}
    - hosts:
        - {{ .host | quote }}
      {{- if .secretName }}
      secretName: {{ .secretName | quote }}
      {{- else }}
      secretName: tls-acme-{{ .host | replace "*" "wildcard" }}
      {{- end }}
    {{- end }}
  rules:
    {{- range .rules }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: Prefix
            backend:
              service:
                name: {{ .backend.serviceName }}
                port:
                  number: {{ .backend.servicePort | default 80 }}
          {{- end }}
    {{- end }}
---
{{- end }}
{{- end }}
