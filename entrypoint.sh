#!/bin/sh
set -e

# --- Configurar la carpeta de datos dentro de /app ---
ODOO_DATA_DIR="/app/data"
export ODOO_DATA_DIR

mkdir -p "$ODOO_DATA_DIR/filestore"
mkdir -p "$ODOO_DATA_DIR/sessions"
chown -R odoo:odoo "$ODOO_DATA_DIR"
echo "✅ Filestore path: $ODOO_DATA_DIR"

# --- Esperar la base de datos ---
echo "🔹 Waiting for database..."
while ! nc -z ${ODOO_DATABASE_HOST} ${ODOO_DATABASE_PORT} 2>/dev/null; do sleep 1; done;
echo "✅ Database is now available"

# --- Variables ---
DB_HOST=${ODOO_DATABASE_HOST}
DB_PORT=${ODOO_DATABASE_PORT}
DB_USER=${ODOO_DATABASE_USER}
DB_PASSWORD=${ODOO_DATABASE_PASSWORD}
DB_NAME=${ODOO_DATABASE_NAME}

# --- Verificar si la base de datos existe ---
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -p $DB_PORT -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" || true)

if [ -z "$DB_EXISTS" ] || [ "$DB_EXISTS" != "1" ]; then
    echo "🚀 Database '$DB_NAME' not found. Creating and initializing..."
    createdb -h $DB_HOST -U $DB_USER -p $DB_PORT $DB_NAME || true
    odoo -i base --without-demo=True --stop-after-init \
         --data-dir="$ODOO_DATA_DIR" \
         --db_host="${DB_HOST}" \
         --db_port="${DB_PORT}" \
         --db_user="${DB_USER}" \
         --db_password="${DB_PASSWORD}" \
         --database="${DB_NAME}" \
         --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
else
    echo "✅ Database '$DB_NAME' already exists."
fi

# --- Ejecutar Odoo ---
echo "🚀 Starting Odoo..."
exec odoo \
    --http-port="${PORT:-8069}" \
    --data-dir="$ODOO_DATA_DIR" \
    --without-demo=True \
    --proxy-mode \
    --db_host="${DB_HOST}" \
    --db_port="${DB_PORT}" \
    --db_user="${DB_USER}" \
    --db_password="${DB_PASSWORD}" \
    --database="${DB_NAME}" \
    --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
