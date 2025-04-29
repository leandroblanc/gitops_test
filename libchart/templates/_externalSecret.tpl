{{- define "libchart.externalSecret" }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $.Release.Name }}-externalsecret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: {{ $.Values.externalSecret.secretStore.name | default "aws-secret-store" }}
    kind: SecretStore
  target:
    name: {{ $.Values.fullnameOverride }}-secret
    creationPolicy: Owner
  data:
  {{- range $key, $value := $.Values.env.secrets }}
  - secretKey: {{ $key }}
    remoteRef:
      key: {{ $value.name }}  # Works for both Secrets Manager and SSM
  {{- end }}
{{- end }}
