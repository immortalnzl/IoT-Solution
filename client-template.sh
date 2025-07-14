#!/bin/bash

TEMPLATE_DIR="./client-template"
DEST_DIR="./clients"

read -p "Enter client name (e.g. client-abc): " CLIENT_NAME
CLIENT_SLUG=$(echo "$CLIENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
CLIENT_DIR="${DEST_DIR}/${CLIENT_SLUG}"

if [ -d "$CLIENT_DIR" ]; then
  echo "❌ Client already exists at $CLIENT_DIR"
  exit 1
fi

echo "📁 Creating client stack in $CLIENT_DIR ..."
mkdir -p "$CLIENT_DIR"
cp -r "$TEMPLATE_DIR/." "$CLIENT_DIR/"

# Generate secure token (can replace with openssl or uuidgen if needed)
INFLUX_TOKEN=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c32)

# Create .env file
cat > "$CLIENT_DIR/.env" <<EOF
CLIENT_NAME=${CLIENT_SLUG}
CLIENT_ORG=${CLIENT_SLUG}-org
INFLUX_BUCKET=telegraf
INFLUX_TOKEN=${INFLUX_TOKEN}
GRAFANA_PASSWORD=admin123
EOF

echo "✅ Created .env with token: ${INFLUX_TOKEN}"
# Create a datasource link
cat > "$CLIENT_DIR/grafana/provisioning/datasources/influxdb.yml" << EOF
apiVersion: 1
datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    jsonData:
      version: Flux
      organization: ${CLIENT_SLUG}-org
      defaultBucket: telegraf
    secureJsonData:
      token: ${INFLUX_TOKEN}
    isDefault: true
EOF

# Optionally launch stack
read -p "🚀 Launch Docker stack now? (y/n): " LAUNCH
if [[ "$LAUNCH" == "y" ]]; then
  cd "$CLIENT_DIR" || exit
  docker compose up -d
  echo "✅ Stack started at $CLIENT_DIR"
else
  echo "📦 Stack ready at $CLIENT_DIR — run 'docker compose up -d' inside it when ready."
fi
