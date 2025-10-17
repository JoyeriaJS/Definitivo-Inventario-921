#!/bin/sh
set -e

echo "🔹 Waiting for database..."
while ! nc -z ${ODOO_DATABASE_HOST} ${ODOO_DATABASE_PORT} 2>&1; do sleep 1; done;
echo "✅ Database is now available"

# Check if the database exists
DB_EXISTS=$(PGPASSWORD=$ODOO_DATABASE_PASSWORD psql -h $ODOO_DATABASE_HOST -U $ODOO_DATABASE_USER -p $ODOO_DATABASE_PORT -tAc "SELECT 1 FROM pg_database WHERE datname='${ODOO_DATABASE_NAME}';")

# Si la base no existe o está vacía → instalar módulo base
if [ "$DB_EXISTS" != "1" ]; then
    echo "🚀 Database '${ODOO_DATABASE_NAME}' not found or not initialized. Initializing Odoo..."
    exec odoo \
        -i base \
        --without-demo=True \
        --stop-after-init \
        --db_host="${ODOO_DATABASE_HOST}" \
        --db_port="${ODOO_DATABASE_PORT}" \
        --db_user="${ODOO_DATABASE_USER}" \
        --db_password="${ODOO_DATABASE_PASSWORD}" \
        --database="${ODOO_DATABASE_NAME}" \
        --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
fi

# Si la base ya existe → arrancar normalmente
echo "✅ Database '${ODOO_DATABASE_NAME}' already exists. Starting Odoo..."
exec odoo \
    --http-port="${PORT}" \
    --without-demo=True \
    --proxy-mode \
    --db_host="${ODOO_DATABASE_HOST}" \
    --db_port="${ODOO_DATABASE_PORT}" \
    --db_user="${ODOO_DATABASE_USER}" \
    --db_password="${ODOO_DATABASE_PASSWORD}" \
    --database="${ODOO_DATABASE_NAME}" \
    --smtp="${ODOO_SMTP_HOST}" \
    --smtp-port="${ODOO_SMTP_PORT_NUMBER}" \
    --smtp-user="${ODOO_SMTP_USER}" \
    --smtp-password="${ODOO_SMTP_PASSWORD}" \
    --email-from="${ODOO_EMAIL_FROM}" \
    --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
