#!/bin/sh
set -e

# --- Configurar carpeta de datos ---
ODOO_DATA_DIR="/app/data"
export ODOO_DATA_DIR
mkdir -p "$ODOO_DATA_DIR/filestore"
chown -R odoo:odoo "$ODOO_DATA_DIR"
echo "✅ Filestore path: $ODOO_DATA_DIR"

# --- Esperar base de datos ---
echo "🔹 Waiting for database..."
while ! nc -z ${ODOO_DATABASE_HOST:-$PGHOST} ${ODOO_DATABASE_PORT:-$PGPORT} 2>/dev/null; do sleep 1; done
echo "✅ Database is now available"

# --- Variables compatibles con Railway ---
DB_HOST=${ODOO_DATABASE_HOST:-$PGHOST}
DB_PORT=${ODOO_DATABASE_PORT:-$PGPORT}
DB_USER=${ODOO_DATABASE_USER:-$PGUSER}
DB_PASSWORD=${ODOO_DATABASE_PASSWORD:-$PGPASSWORD}
DB_NAME=${ODOO_DATABASE_NAME:-$PGDATABASE}

echo "🔹 Checking database connection on $DB_HOST:$DB_PORT → $DB_NAME"

# --- Verificar existencia sin prompt de contraseña ---
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" 2>/dev/null || true)

# --- Inicializar si no existe ---
if [ "$DB_EXISTS" != "1" ]; then
    echo "🚀 Database '$DB_NAME' not found. Creating and initializing..."
    PGPASSWORD=$DB_PASSWORD createdb -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" "$DB_NAME" || true
    odoo -i base --without-demo=True --stop-after-init \
         --data-dir="$ODOO_DATA_DIR" \
         --db_host="$DB_HOST" \
         --db_port="$DB_PORT" \
         --db_user="$DB_USER" \
         --db_password="$DB_PASSWORD" \
         --database="$DB_NAME" \
         --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
else
    echo "✅ Database '$DB_NAME' already exists."
fi

# --- Instalar automáticamente módulos personalizados ---
echo "🔹 Checking for custom modules to install..."
PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$DB_NAME" -tAc \
"SELECT name FROM ir_module_module WHERE state='installed';" > /tmp/installed_modules.txt

for module_path in /mnt/custom_addons/*/; do
    module_name=$(basename "$module_path")
    if ! grep -q "$module_name" /tmp/installed_modules.txt; then
        echo "🧩 Installing missing module: $module_name"
        odoo --stop-after-init \
             -i "$module_name" \
             --data-dir="$ODOO_DATA_DIR" \
             --db_host="$DB_HOST" \
             --db_port="$DB_PORT" \
             --db_user="$DB_USER" \
             --db_password="$DB_PASSWORD" \
             --database="$DB_NAME" \
             --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
    else
        echo "✔️ Module already installed: $module_name"
    fi
done

# --- Iniciar Odoo normalmente ---
echo "🚀 Starting Odoo..."
exec odoo \
    --http-port="${PORT:-8069}" \
    --data-dir="$ODOO_DATA_DIR" \
    --without-demo=True \
    --proxy-mode \
    --db_host="$DB_HOST" \
    --db_port="$DB_PORT" \
    --db_user="$DB_USER" \
    --db_password="$DB_PASSWORD" \
    --database="$DB_NAME" \
    --addons-path=/mnt/custom_addons,/usr/lib/python3/dist-packages/odoo/addons
