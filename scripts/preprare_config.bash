#!/usr/bin/env bash

set -exu

[[ -f docker-compose.yml ]] || {
  echo "Please run me from dir with docker-compose.yml"
  exit 1
}

declare cosul_poc_root=$PWD
declare ca_file='templates/ca.pem'
declare ca_key_file='templates/ca-key.pem'

declare gossip_encryption_key='VhPBrehv0113moXGHevkEA=='
declare primary_datacenter='dc1'
declare retry_join_wan='[]'

declare -a client_names=(
  consul-dc1-agent-1
  consul-dc1-agent-2
  consul-dc1-agent-3
  consul-dc2-agent-1
  consul-dc3-agent-1
)

declare -a server_names=(
  consul-dc1-server-1
  consul-dc1-server-2
  consul-dc1-server-3
  consul-dc2-server-1
  consul-dc2-server-2
  consul-dc2-server-3
  consul-dc3-server-1
  consul-dc3-server-2
  consul-dc3-server-3
)

declare -A servers_to_join=(
  [dc1]='["172.16.0.11", "172.16.0.12", "172.16.0.13"]'
  [dc2]='["172.16.1.11", "172.16.1.12", "172.16.1.13"]'
  [dc3]='["172.16.2.11", "172.16.2.12", "172.16.2.13"]'
)

for dc_servers in "${servers_to_join[@]}"; do
  retry_join_wan=$(jq --argjson dcs "$dc_servers" '. + $dcs' <<< "$retry_join_wan")
done

for client in "${client_names[@]}"; do
  mkdir -p "consul_client/config/$client"
  dc=${client#consul-}
  dc=${dc%%-*}
  jq -n -e --arg gossip_encryption_key "$gossip_encryption_key" \
     --arg datacenter "$dc" \
     --arg node_name "$client" \
     --argjson servers_to_join "${servers_to_join["$dc"]}" \
     -f templates/client.jq \
   > "consul_client/config/$client/config.json"
  (
    mkdir -p "consul_client/certs/$client"
    jq -n -e --arg cn "$client" -f templates/client-crs.jq \
     > "consul_client/certs/$client/client.json"
    cd "consul_client/certs/$client"
    cfssl gencert -ca="$cosul_poc_root/templates/ca.pem" \
      -ca-key="$cosul_poc_root/templates/ca-key.pem" \
      -config="$cosul_poc_root/templates/ca-config.json" \
      -profile=client 'client.json' | cfssljson -bare client
    # consul in container has uid(100) and guid(1000) and my uer has uid(1000) guid(1000)
    # so this is hack to give consul user perms to certs without sudo chown
    chmod g+rw *
  )
done; unset client dc

for server in "${server_names[@]}"; do
  mkdir -p "consul_server/config/$server"
  dc=${server#consul-}
  dc=${dc%%-*}
  jq -n -e --arg gossip_encryption_key "$gossip_encryption_key" \
     --arg primary_datacenter "$primary_datacenter" \
     --arg datacenter "$dc" \
     --arg node_name "$server" \
     --argjson retry_join_wan "${retry_join_wan[@]}" \
     --argjson servers_to_join "${servers_to_join["$dc"]}" \
     -f templates/server.jq \
   > "consul_server/config/$server/config.json"
  (
    mkdir -p "consul_server/certs/$server"
    jq -n -e --arg cn "$server" \
       --argjson hosts "[\"127.0.0.1\",\"localhost\", \"$server\", \"server.$dc.consul\"]" \
       -f templates/server-crs.jq \
     > "consul_server/certs/$server/server.json"
    cd "consul_server/certs/$server"
    cfssl gencert -ca="$cosul_poc_root/templates/ca.pem" \
      -ca-key="$cosul_poc_root/templates/ca-key.pem" \
      -config="$cosul_poc_root/templates/ca-config.json" \
      -profile=server 'server.json' | cfssljson -bare server
    # consul in container has uid(100) and guid(1000) and my uer has uid(1000) guid(1000)
    # so this is hack to give consul user perms to certs without sudo chown
    chmod g+rw *
  )
done; unset server dc