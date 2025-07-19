#!/bin/bash

TEMPLATE_DIR="./monitoring-template"
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

# Generate secure token
INFLUX_TOKEN=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c32)

# Create .env
cat > "$CLIENT_DIR/.env" <<EOF
CLIENT_NAME=${CLIENT_SLUG}
CLIENT_ORG=${CLIENT_SLUG}-org
INFLUX_BUCKET=telegraf
INFLUX_TOKEN=${INFLUX_TOKEN}
GRAFANA_PASSWORD=admin123
EOF

echo "✅ Created .env with token: ${INFLUX_TOKEN}"

# Inject values into grafana datasource
DATASOURCE_FILE="$CLIENT_DIR/grafana/provisioning/datasources/datasource.yaml"
if [ -f "$DATASOURCE_FILE" ]; then
  sed -i "s|__CLIENT_ORG__|${CLIENT_SLUG}-org|g" "$DATASOURCE_FILE"
  sed -i "s|__INFLUX_TOKEN__|${INFLUX_TOKEN}|g" "$DATASOURCE_FILE"
  sed -i "s|__CLIENT_NAME__|${CLIENT_SLUG}|g" "$DATASOURCE_FILE"
else
  echo "⚠️ Warning: $DATASOURCE_FILE not found. Skipping datasource update."
fi

# Add Mosquitto config
MOSQ_DIR="$CLIENT_DIR/mosquitto/config"
mkdir -p "$MOSQ_DIR"
cat > "$MOSQ_DIR/mosquitto.conf" <<EOF
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

echo "✅ Mosquitto MQTT config added."

# Launch stack
read -p "🚀 Launch Docker stack now? (y/n): " LAUNCH
if [[ "$LAUNCH" == "y" ]]; then
  cd "$CLIENT_DIR" || exit
  docker compose up -d
  echo "✅ Stack started at $CLIENT_DIR"
else
  echo "📦 Stack ready at $CLIENT_DIR — run 'docker compose up -d' inside it when ready."
fi
