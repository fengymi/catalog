{{- define "vaultwarden.configuration" -}}

  {{- if and .Values.vaultwardenNetwork.domain (not (hasPrefix "http" .Values.vaultwardenNetwork.domain)) -}}
    {{- fail "Vaultwarden - Expected [Domain] to have the following format [http(s)://(sub).domain.tld(:port)]." -}}
  {{- end -}}

  {{- $dbUser := "vaultwarden" -}}
  {{- $dbName := "vaultwarden" -}}
  {{- $dbHost := "vaultwarden_host_ignore_test" -}}
  {{- $dbPass := "vaultwarden_password_ignore_test" -}}


  {{/* Temporary set dynamic db details on values,
  so we can print them on the notes */}}
  {{- $_ := set .Values "vaultwardenDbHost" $dbHost -}}

secret:
  postgres-creds:
    enabled: true
    data:
      POSTGRES_USER: {{ $dbUser }}
      POSTGRES_DB: {{ $dbName }}
      POSTGRES_PASSWORD: {{ $dbPass }}
  {{ with .Values.vaultwardenConfig.adminToken }}
  vaultwarden:
    enabled: true
    data:
      ADMIN_TOKEN: {{ . | quote }}
  {{ end }}
{{- end -}}
