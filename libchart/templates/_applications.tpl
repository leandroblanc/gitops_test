# Define template
{{- define "libchart.applications" }}

# Range across all clusters defined in apps/values.yaml
{{ range .Values.clusters }}
# Assign the current cluster to $cluster
{{- $cluster := . }}

# Range across all applications defined in apps/values.yaml
{{ range $.Values.applications }}
# Assign the current app to $app
{{- $app := . }}

# Example: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "{{ $cluster.name }}-{{ $app.name }}"
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
  annotations:
    {{- if $.Values.slackChannel }}
    # We add these notification subscriptions to report problems to Slack. These triggers
    # should be added to the defaultTriggers section of values.yaml.tpl in the tf-argocd repo
    # See these resources:
    # - https://argocd-notifications.readthedocs.io/en/stable/services/slack/
    # - https://argocd-notifications.readthedocs.io/en/stable/catalog/ and
    # - https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/subscriptions/
    notifications.argoproj.io/subscribe.on-sync-failed.slack: {{ $.Values.slackChannel }}
    notifications.argoproj.io/subscribe.on-sync-status-unknown.slack: {{ $.Values.slackChannel }}
    notifications.argoproj.io/subscribe.on-health-degraded.slack: {{ $.Values.slackChannel }}
    {{- end }}
spec:
  project: "{{ $app.project }}"

  destination:
    server: "{{ $cluster.url }}"

    # If no namespace is specified we set the directory name as namespace
    {{- if $app.namespace }}
    namespace: "{{ $app.namespace }}"
    {{- else }}
    namespace: "{{ $app.directory }}"
    {{- end }}

  source:
    path: "{{ $.Values.basePath }}/{{ $app.directory }}"
    repoURL: "{{ $.Values.repoUrl }}"
    targetRevision: "HEAD"

    plugin:
      # The argocd-vault-plugin-helm definition is configured here: tf-argocd/argocd-vault-plugin-helm.yaml
      # The section below is based on https://argocd-vault-plugin.readthedocs.io/en/stable/usage/. Besides providing the value files to parse, we configure the
      # --kube-version and --api-versions settings provided by helm (https://helm.sh/docs/helm/helm_template/). They are used by some charts like Zabbix to know which api versions use.
      name: argocd-vault-plugin-helm
      env:
        - name: HELM_ARGS
          value: --kube-version={{ $.Values.kubeVersion }} --api-versions={{ $.Values.apiVersions }} -f values.yaml {{ $extraValuesFilesArguments }}

  syncPolicy:
    {{- if $app.disableAutomatedSyncs }}
    # Automated synchronizations disabled (eg: to perform a restore or test changes manually)
    {{- else }}
    automated: {}
    {{- end }}
    # https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/
    syncOptions:
    - CreateNamespace=true
    - ServerSideApply={{ default false $app.serverSideApply }}

{{- if $app.ignoreDifferences }}
  ignoreDifferences:
{{- toYaml $app.ignoreDifferences | nindent 4 }}
{{- end }}

# End range .Values.applications
---
{{- end }}

# End range .Values.clusters
{{- end }}

---
# End define "libchart.application"
{{- end }}
