FROM odoo:17.0

# --- Locales ---
ARG LOCALE=en_US.UTF-8
ENV LANGUAGE=${LOCALE}
ENV LC_ALL=${LOCALE}
ENV LANG=${LOCALE}

# --- Instalar dependencias básicas ---
USER root
RUN apt-get update -y && apt-get install -y --no-install-recommends \
        locales \
        netcat-openbsd \
    && locale-gen ${LOCALE} \
    && rm -rf /var/lib/apt/lists/*

# --- Directorio de trabajo ---
WORKDIR /app

# --- Copiar entrypoint y addons ---
COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY ./custom_addons /mnt/custom_addons

# --- Definir entrypoint ---
ENTRYPOINT ["/entrypoint.sh"]

# --- Ejecutar como usuario odoo (por seguridad) ---
USER odoo
