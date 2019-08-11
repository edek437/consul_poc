#!/usr/bin/env bash

set -exu

[[ -f docker-compose.yml ]] || {
  echo "Please run me from dir with docker-compose.yml"
  exit 1
}

declare gossip_encryption_key='VhPBrehv0113moXGHevkEA=='
declare primary_datacenter='dc1'

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
done; unset client dc

for server in "${server_names[@]}"; do
  mkdir -p "consul_server/config/$server"
  dc=${server#consul-}
  dc=${dc%%-*}
  jq -n -e --arg gossip_encryption_key "$gossip_encryption_key" \
     --arg primary_datacenter "$primary_datacenter" \
     --arg datacenter "$dc" \
     --arg node_name "$server" \
     --argjson servers_to_join "${servers_to_join["$dc"]}" \
     -f templates/server.jq \
   > "consul_server/config/$server/config.json"
done; unset server dc