{{/*
Expand the name of the chart.
*/}}
{{- define "django-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "django-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "django-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "django-chart.labels" -}}
helm.sh/chart: {{ include "django-chart.chart" . }}
{{ include "django-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "django-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "django-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "django-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "django-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "wagtail.superuserJob" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Values.superuser.job.name }}
  namespace: {{ .Values.namespace }}
  labels:
    app: {{ .Values.app }}
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: create-superuser
          image: "{{ .Values.image.app.container.image.repository }}:{{ .Values.image.app.container.image.tag }}"
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Checking if superuser exists..."
              python manage.py shell <<EOF
              from django.contrib.auth import get_user_model
              User = get_user_model()
              if not User.objects.filter(username="{{ .Values.superuser.username }}").exists():
                  print("Creating superuser...")
                  User.objects.create_superuser(
                      "{{ .Values.superuser.username }}",
                      "{{ .Values.superuser.email }}",
                      "{{ .Values.superuser.password }}"
                  )
              else:
                  print("Superuser already exists.")
              EOF
          env:
            - name: {{ .Values.env.postgresDbName.name }}
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.aws.secretName }}
                  key: {{ .Values.env.postgresDbName.name }}
            - name: {{ .Values.env.postgresUser.name }}
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.aws.secretName }}
                  key: {{ .Values.env.postgresUser.name }}
            - name: {{ .Values.env.postgresPassword.name }}
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.aws.secretName }}
                  key: {{ .Values.env.postgresPassword.name }}
            - name: {{ .Values.env.postgresHost.name }}
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.aws.secretName }}
                  key: {{ .Values.env.postgresHost.name }}
            - name: {{ .Values.env.postgresPort.name }}
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.aws.secretName }}
                  key: {{ .Values.env.postgresPort.name }}
{{- end }}
