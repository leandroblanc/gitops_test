{{- define "libchart.externalSecret" }}
{{- range $store := .Values.externalSecrets }}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $.Release.Name }}-{{ $store.secretStoreName | kebabcase }}-secret
  labels:
    app.kubernetes.io/name: {{ $.Release.Name }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: {{ $store.secretStoreName }}
    kind: {{ $store.secretStoreType | default "ClusterSecretStore" }}
  target:
    name: {{ $.Release.Name }}-{{ $store.secretStoreName | kebabcase }}-secret
    creationPolicy: Owner
  data:
    {{- range $secret := $store.secrets }}
    - secretKey: {{ $secret.name }}
      remoteRef:
        key: {{ $secret.path }}
    {{- end }}
{{- end }}
{{- end }}
