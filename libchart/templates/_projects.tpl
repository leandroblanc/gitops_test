{{- define "libchart.projects" }}
# Example: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/project.yaml
{{ range .Values.projects }}
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: {{ .name }}
  namespace: argocd
  # Finalizer that ensures that project is not deleted until it is not referenced by any application
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: "{{ .description }}"

  # Allow manifests to deploy from any Git repos
  sourceRepos:
    - '*'

  # Only allow to this project the deployment of apps in the clusters of the current clusterset
  destinations:
    # Range across all clusters defined in apps/values.yaml
    {{ range $.Values.clusters }}
    # Assign the current cluster to $cluster
    {{- $cluster := . }}
    - server: "{{ $cluster.url }}"
      namespace: '*'
    {{- end }}

  # Allow creation of any cluster-scoped resources
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'

  # Allow access to all namespaces
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'

  # Define two roles per project ("read-only" and "full-access")
  # We don't define which groups uses these roles. This is configured in policy_csv (terraform)
  roles:
    # A role which provides read-only access to all applications in the project
    - name: read-only
      description: "Read-only privileges to applications in {{ .name }} project"
      policies:
        - p, proj:{{ .name }}:read-only, applications, get, {{ .name }}/*, allow
    # A role which provides full access to all applications in the project
    - name: full-access
      description: "Full access privileges to applications in {{ .name }} project"
      policies:
        - p, proj:{{ .name }}:full-access, applications, *, {{ .name }}/*, allow
---
{{- end }}
---
{{- end }}
