FROM odoo:17.0

ARG LOCALE=en_US.UTF-8
ENV LANGUAGE=${LOCALE}
ENV LC_ALL=${LOCALE}
ENV LANG=${LOCALE}
ENV ODOO_DATA_DIR=/mnt/filestore

USER root

RUN apt-get update -y && apt-get install -y --no-install-recommends locales netcat-openbsd \
    && locale-gen ${LOCALE}

WORKDIR /app

COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY ./custom_addons /mnt/custom_addons

ENTRYPOINT ["/entrypoint.sh"]
USER odoo
