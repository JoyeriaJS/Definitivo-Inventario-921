#!/bin/sh
set -e

echo "🔹 Waiting for database..."
while ! nc -z ${ODOO_DATABASE_HOST:-$PGHOST} ${ODOO_DATABASE_PORT:-$PGPORT} 2>&1; do sleep 1; done;
echo "✅ Database is now available"

# Usa las variables de Railway si no están definidas las de Odoo
DB_HOST=${ODOO_DATABASE_HOST:-$PGHOST}
DB_PORT=${ODOO_DATABASE_PORT:-$PGPORT}
DB_USER=${ODOO_DATABASE_USER:-$PGUSER}
DB_PASSWORD=${ODOO_DATABASE_PASSWORD:-$PGPASSWORD}
DB_NAME=${ODOO_DATABASE_NAME:-$PGDATABASE}

echo "🔹 Using database: $DB_NAME"

# Verificar si la base existe (Railway crea PGDATABASE automáticamente)
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -p $DB_PORT -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" || true)

if [ -z "$DB_EXISTS" ] || [ "$DB_EXISTS" != "1" ]; then
    echo "🚀 Database '$DB_NAME' not found or not initialized. Initializing Odoo..."
    exec odoo \
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

echo "✅ Database '$DB_NAME' already exists. Starting Odoo..."
exec odoo \
    --http-port="${PORT}" \
    --without-demo=True \
    --proxy-mode \
    --db_host="${DB_HOST}" \
    --db_port="${DB_PORT}" \
    --db_user="${DB_USER}" \
    --db_password="${DB_PASSWORD}" \
    --database="${DB_NAME}" \
    --smtp="${ODOO_SMTP_HOST}" \
    --smtp-port="${ODOO_SMTP_PORT_NUMBER}" \
    --smtp-user="${ODOO_SMTP_USER}" \
    --smtp-password="${ODOO_SMTP_PASSWORD}" \
    --email-from="${ODOO_EMAIL_FROM}" \
    --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
