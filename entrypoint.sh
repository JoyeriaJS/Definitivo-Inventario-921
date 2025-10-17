#!/bin/sh
set -e

# --- Configuración inicial ---
# Railway no permite escribir en /var/lib, por lo que usamos /mnt/filestore
ODOO_DATA_DIR="/mnt/filestore"
export ODOO_DATA_DIR

echo "🔹 Using Odoo filestore path: $ODOO_DATA_DIR"
mkdir -p "$ODOO_DATA_DIR"
chown -R odoo:odoo "$ODOO_DATA_DIR"

# --- Esperar a que PostgreSQL esté disponible ---
echo "🔹 Waiting for database..."
while ! nc -z ${ODOO_DATABASE_HOST:-$PGHOST} ${ODOO_DATABASE_PORT:-$PGPORT} 2>/dev/null; do sleep 1; done;
echo "✅ Database is now available"

# --- Variables de entorno (Railway las inyecta automáticamente) ---
DB_HOST=${ODOO_DATABASE_HOST:-$PGHOST}
DB_PORT=${ODOO_DATABASE_PORT:-$PGPORT}
DB_USER=${ODOO_DATABASE_USER:-$PGUSER}
DB_PASSWORD=${ODOO_DATABASE_PASSWORD:-$PGPASSWORD}
DB_NAME=${ODOO_DATABASE_NAME:-$PGDATABASE}

echo "🔹 Using database: $DB_NAME"

# --- Verificar si la base de datos existe ---
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -p $DB_PORT -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" || true)

# --- Inicializar si no existe ---
if [ -z "$DB_EXISTS" ] || [ "$DB_EXISTS" != "1" ]; then
    echo "🚀 Database '$DB_NAME' not found or not initialized. Initializing Odoo..."
    odoo \
        -i base \
        --without-demo=True \
        --stop-after-init \
        --db_host="${DB_HOST}" \
        --db_port="${DB_PORT}" \
        --db_user="${DB_USER}" \
        --db_password="${DB_PASSWORD}" \
        --database="${DB_NAME}" \
        --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
fi

# --- Ejecutar Odoo normalmente ---
echo "✅ Database '$DB_NAME' ready. Starting Odoo..."
exec odoo \
    --http-port="${PORT:-8069}" \
    --without-demo=True \
    --proxy-mode \
    --db_host="${DB_HOST}" \
    --db_port="${DB_PORT}" \
    --db_user="${DB_USER}" \
    --db_password="${DB_PASSWORD}" \
    --database="${DB_NAME}" \
    --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
