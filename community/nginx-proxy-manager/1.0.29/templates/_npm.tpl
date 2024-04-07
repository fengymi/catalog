{{- define "npm.workload" -}}
{{- if not .Values.npmID -}}
  {{- $_ := set .Values "npmID" dict -}}
{{- end }}
workload:
  npm:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: false
      securityContext:
        fsGroup: {{ .Values.npmID.group | default 1000 }}
      containers:
        npm:
          enabled: true
          primary: true
          imageSelector: image
          securityContext:
            runAsUser: 0
            runAsGroup: 0
            readOnlyRootFilesystem: false
            runAsNonRoot: false
            capabilities:
              add:
                # Needed for: s6-applyuidgid: fatal: unable to setuid: Operation not permitted
                - SETUID
                # Needed for: s6-applyuidgid: fatal: unable to set supplementary group list: Operation not permitted
                - SETGID
                # Needed for: Used in some s6-overlay startup scripts
                - CHOWN
                - DAC_OVERRIDE
                # Needed for: Nginx Service
                - FOWNER
          fixedEnv:
            PUID: {{ .Values.npmID.user | default 1000 }}
          env:
            DB_MYSQL_HOST: "{{ .Values.database.mysql_host }}"
            DB_MYSQL_PORT: {{ .Values.database.mysql_host_port }}
            DB_MYSQL_NAME: "{{ .Values.database.mysql_db_name }}"
            DB_MYSQL_USER: "{{ .Values.database.mysql_user }}"
            DB_MYSQL_PASSWORD: "{{ .Values.database.mysql_password }}"
            DISABLE_IPV6: {{ .Values.database.disable_ipv6 }}
          {{ with .Values.npmConfig.additionalEnvs }}
          envList:
            {{ range $env := . }}
            - name: {{ $env.name }}
              value: {{ $env.value }}
            {{ end }}
          {{ end }}
          probes:
            liveness:
              enabled: true
              type: exec
              command: /bin/check-health
            readiness:
              enabled: true
              type: exec
              command: /bin/check-health
            startup:
              enabled: true
              type: exec
              command: /bin/check-health
              spec:
                initialDelaySeconds: 30
                failureThreshold: 180
{{/* Service */}}
service:
  npm:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: npm
    ports:
      webui:
        enabled: true
        primary: true
        port: {{ .Values.npmNetwork.webPort }}
        nodePort: {{ .Values.npmNetwork.webPort }}
        targetPort: 81
        targetSelector: npm
      http:
        enabled: true
        port: {{ .Values.npmNetwork.httpPort }}
        nodePort: {{ .Values.npmNetwork.httpPort }}
        targetPort: 80
        targetSelector: npm
      https:
        enabled: true
        port: {{ .Values.npmNetwork.httpsPort }}
        nodePort: {{ .Values.npmNetwork.httpsPort }}
        targetPort: 443
        targetSelector: npm

{{/* Persistence */}}
persistence:
  data:
    enabled: true
    type: {{ .Values.npmStorage.data.type }}
    datasetName: {{ .Values.npmStorage.data.datasetName | default "" }}
    hostPath: {{ .Values.npmStorage.data.hostPath | default "" }}
    targetSelector:
      npm:
        npm:
          mountPath: /data
  certs:
    enabled: true
    type: {{ .Values.npmStorage.certs.type }}
    datasetName: {{ .Values.npmStorage.certs.datasetName | default "" }}
    hostPath: {{ .Values.npmStorage.certs.hostPath | default "" }}
    targetSelector:
      npm:
        npm:
          mountPath: /etc/letsencrypt

  {{ if .Values.npmStorage.opt }}
  opt:
    enabled: true
    type: {{ .Values.npmStorage.opt.type }}
    datasetName: {{ .Values.npmStorage.opt.datasetName | default "" }}
    hostPath: {{ .Values.npmStorage.opt.hostPath | default "" }}
    targetSelector:
      npm:
        npm:
          mountPath: {{ .Values.npmStorage.opt.mountPath | default "" }}
  {{ end }}
{{- end -}}
