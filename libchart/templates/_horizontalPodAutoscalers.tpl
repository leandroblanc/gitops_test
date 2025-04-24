{{- define "libchart.horizontalPodAutoscalers" }}
{{- range .Values.horizontalPodAutoscalers }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .deploymentName }}
  labels:
    app.kubernetes.io/name: {{ .deploymentName }}
    app.kubernetes.io/instance: {{ .deploymentName }}
    app.kubernetes.io/managed-by: Helm
spec:
  scaleTargetRef:
    # Set apiVersion and Kind (depending if we use canary or not)
    {{- if $.Values.canary }}
    # https://argoproj.github.io/argo-rollouts/features/specification/
    apiVersion: argoproj.io/v1alpha1
    kind: Rollout
    {{- else }}
    # https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
    apiVersion: apps/v1
    kind: Deployment
    {{- end }}
    name: {{ .deploymentName }}
  minReplicas: {{ .minReplicas | default 2 }}
  maxReplicas: {{ .maxReplicas | default 2 }}
  metrics:
    {{- if .targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .targetMemoryUtilizationPercentage }}
    {{- end }}
    {{- if .targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .targetCPUUtilizationPercentage }}
    {{- end }}
---
{{- end }}
{{- end }}
