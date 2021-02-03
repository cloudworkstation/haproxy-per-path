FROM haproxy:2.3.4-alpine

RUN apk update
RUN apk add jq gettext libintl

COPY haproxy-template.cfg /
COPY create-config.sh /

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]

