{{- define "libchart.deployments" }}
{{- range .Values.deployments }}

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

metadata:
  name: {{ .name }}
  labels:
    app.kubernetes.io/name: {{ .name }}
    app.kubernetes.io/version: "1.0"
    app.kubernetes.io/managed-by: "Helm"
spec:
  {{- if .replicaCount }}
  replicas: {{ .replicaCount }}
  {{- end }}
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .name }}
  strategy:
    {{- if .strategy }}
    {{- toYaml .strategy | nindent 4 }}
    {{- else }}

    {{- if $.Values.canary }}
    # Canary configuration
    canary:
      stableService: {{ .name }}
      canaryService: {{ .name }}-canary
      # Disabling traffic router integration. For details see docs/argo-rollouts/README.md
      # https://rollouts-plugin-trafficrouter-gatewayapi.readthedocs.io/en/latest/quick-start/
      #trafficRouting:
      #  maxTrafficWeight: 100
      #  managedRoutes:
      #    - name: {{ printf "%s-%s-%s" $.Values.mesh .name $.Values.cluster -}}-https
      #  plugins:
      #    argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi:
      #      httpRoute: {{ printf "%s-%s-%s" $.Values.mesh .name $.Values.cluster -}}-https
      #      namespace: {{ $.Release.Namespace }}
      steps:
        {{- toYaml $.Values.steps | nindent 8 }}
    {{- else }}
    # Regular deployment. Instead by using a percentage, we indicate the number of pods (create one pod while another one is terminated)
    # This configuration is optimized to minimize the number of extra pods during an upgrade. Although this strategy makes the upgrade a bit slower, it's safer.
    # For details see https://medium.com/@bubu.tripathy/understanding-maxsurge-and-maxunavailable-4966dfafc8ba
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    {{- end }}

    # End if .strategy
    {{- end }}

  # Template
  template:
    metadata:
      annotations:
        # This annotation reloads the pod when a configmap or secret changes
        reloader.stakater.com/auto: "true"
        # This annotation activates a custom kyverno policy to inject the docker image in the IMAGE_VERSION env variable
        kyverno/inject-image-version-env: "true"
        {{- if .annotations }}
        {{- toYaml .annotations | nindent 8 }}
        {{- end }}
      labels:
        app.kubernetes.io/name: {{ .name }}
    spec:
      #imagePullSecrets:
      #- name: docker-registry
      {{- if .nodeSelector }}
      nodeSelector:
        {{- toYaml .nodeSelector | nindent 8 }}
      {{- end }}
      {{- if .tolerations }}
      tolerations:
        {{- toYaml .tolerations | nindent 8 }}
      {{- end }}
      {{- if .serviceAccountName }}
      serviceAccountName: {{ .serviceAccountName }}
      {{- end }}
      {{- if .volumes }}
      volumes:
        {{- toYaml .volumes | nindent 8 }}
      {{- end }}
      containers:
      - name: {{ .name }}
        {{- if .image }}
        image: {{ .image }}
        {{- else }}
        image: {{ $.Values.image.repository }}:{{ $.Values.image.tag }}
        {{- end }}
        {{- if .securityContext }}
        securityContext:
          {{- toYaml .securityContext | nindent 10 }}
        {{- end }}
        imagePullPolicy: IfNotPresent
        {{- if .command }}
        command:
        {{- range .command }}
          - {{ . | quote }}
        {{- end }}
        {{- end }}
        {{- if .args }}
        args:
          {{- toYaml .args | nindent 10 }}
        {{- end }}
        {{- if .containerPort }}
        ports:
        - containerPort: {{ .containerPort }}
          protocol: TCP
        {{- end }}
        {{- if .volumeMounts }}
        volumeMounts:
          {{- toYaml .volumeMounts | nindent 10 }}
        {{- end }}
        {{- if .env }}
        env:
          # The IMAGE_VERSION env variable is injected by Kyverno
          # Inject the rest of the environment variables configured
          {{- with .env }}
          {{- range $key, $val := . }}        
          - name: {{ $key | quote }}
            value: {{ $val | quote }}
          {{- end }}
          {{- end }}
        {{- end }}
        envFrom:
          - configMapRef:
              name: {{ $.Release.Name }}-configmap
          {{- if .secretName }}
          - secretRef:
              name: {{ .secretName }}
          {{- end }}
        livenessProbe:
          {{- toYaml .livenessProbe | nindent 10 }}
        readinessProbe:
          {{- toYaml .readinessProbe | nindent 10 }}        
        resources:
          {{- toYaml .resources | nindent 10 }}
        # Wait/sleep 15 seconds before terminating main pod in case we use a service mesh that needs to deregister first
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sleep", "15"]
      terminationGracePeriodSeconds: 60
      {{- if .sidecarContainer }}
      {{- toYaml .sidecarContainer | nindent 6 }}
      {{- end }}
      {{- if .initContainers }}
      initContainers:
      {{- range .initContainers }}
      - name: {{ .name }}-init
        image: {{ $.Values.image.repository }}:{{ $.Values.image.tag }}
        imagePullPolicy: IfNotPresent
        {{- if .command }}
        command:
        {{- range .command}}
          - {{ . }}
        {{- end }}
        {{- end }}
        {{- if .args }}
        args:
        {{- range .args }}
          - {{ . }}
        {{- end }}
        {{- end }}
        envFrom:
          - configMapRef:
              name: {{ $.Release.Name }}-configmap
          - secretRef:
              name: {{ $.Release.Name }}-secret
        {{- if .volumeMounts }}
        volumeMounts:
          {{- toYaml .volumeMounts | nindent 10 }}
        {{- end }}
      {{- end }}
      {{- end }}
---
# Define pod disruption budget (PDB) for this deployment
# By default at least 1 pod should be available at every moment
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .name }}
spec:
  minAvailable: {{ .minAvailable | default 1 }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .name }}
---
{{- end }}
{{- end }}
