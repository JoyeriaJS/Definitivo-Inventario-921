FROM odoo:17.0

ARG LOCALE=en_US.UTF-8
ENV LANGUAGE=${LOCALE}
ENV LC_ALL=${LOCALE}
ENV LANG=${LOCALE}

USER root

RUN apt-get update -y && apt-get install -y --no-install-recommends \
        locales \
        netcat-openbsd \
        postgresql-client \
    && locale-gen ${LOCALE} \
    && rm -rf /var/lib/apt/lists/*

# --- Carpeta de trabajo ---
WORKDIR /app

COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY ./custom_addons /mnt/custom_addons

# --- Crear la carpeta de datos dentro de /app ---
RUN mkdir -p /app/data && chown -R odoo:odoo /app/data

ENTRYPOINT ["/entrypoint.sh"]
USER odoo
