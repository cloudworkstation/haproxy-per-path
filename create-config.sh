#!/bin/sh

backend_block="

backend {NAME}
  balance roundrobin
  mode http
  option httpclose
  option forwardfor
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]
  server-template {NAME} {NUM} {DNS_NAME} resolvers mydns check init-addr none"

frontend_block="

  acl {PATH} path_beg /{PATH}
    use_backend {NAME} if {PATH}"

#
# input='[{"name":"api_route", "path":"api", "number": "5","dns":"_api._tcp.cluster.local"}, {"name":"console_route", "path":"console", "number": "5","dns":"_console._tcp.cluster.local"}]'
#

BACKENDS=""
FRONTENDS=""
for row in $(echo "${input}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 -d | jq -r ${1}
    }

   path=$(_jq '.path')
   number=$(_jq '.number')
   dns=$(_jq '.dns')
   name=$(_jq '.name')
   backend_replaced=$(echo "$backend_block" | sed -e "s|{NAME}|$name|g")
   backend_replaced=$(echo "$backend_replaced" | sed -e "s|{NUM}|$number|g")
   backend_replaced=$(echo "$backend_replaced" | sed -e "s|{DNS_NAME}|$dns|g")
   frontend_replaced=$(echo "$frontend_block" | sed -e "s|{NAME}|$name|g")
   frontend_replaced=$(echo "$frontend_replaced" | sed -e "s|{PATH}|$path|g")
   #replaced=$(echo "$locationblock" | sed -e "s|{folder}|$folder|g")
   BACKENDS="$BACKENDS $backend_replaced"
   FRONTENDS="$FRONTENDS $frontend_replaced"
done

echo "Backend config..."
echo "$BACKENDS"

echo "Frontend ACL config..."
echo "$FRONTENDS"

export BACKENDS
export FRONTENDS
envsubst '${BACKENDS} ${FRONTENDS}' < haproxy-template.cfg > /usr/local/etc/haproxy/haproxy.cfg


