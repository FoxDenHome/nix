job_name: homeassistant
metrics_path: /api/prometheus
authorization:
  credentials: '__HOMEASSISTANT_API_TOKEN__'
scheme: https
static_configs:
  - targets: ['homeassistant.foxden.network:443']
