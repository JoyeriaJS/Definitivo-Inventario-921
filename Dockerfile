FROM odoo:17.0

ARG LOCALE=en_US.UTF-8
ENV LANGUAGE=${LOCALE}
ENV LC_ALL=${LOCALE}
ENV LANG=${LOCALE}

USER root

RUN apt-get update -y && apt-get install -y --no-install-recommends locales netcat-openbsd \
    && locale-gen ${LOCALE} \
    && mkdir -p /var/lib/odoo/filestore \
    && chown -R odoo:odoo /var/lib/odoo

WORKDIR /app

COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY ./custom_addons /mnt/custom_addons

ENTRYPOINT ["/entrypoint.sh"]
USER odoo
