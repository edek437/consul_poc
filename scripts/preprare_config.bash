#!/usr/bin/env bash

set -exu

[[ -f docker-compose.yml ]] || {
  echo "Please run me from root dir"
  exit 1
}

declare -a client_names=(
  consul-agent-1
  consul-agent-2
  consul-agent-3
)

declare -a server_names=(
  consul-server-1
  consul-server-2
  consul-server-3
)

for client in "${client_names[@]}"; do
  mkdir -p "consul_client/config/$client"
  jq -n --arg node_name "$client" -f templates/client.jq \
    > "consul_client/config/$client/config.json"
done

for server in "${server_names[@]}"; do
  mkdir -p "consul_server/config/$server"
  jq -n --arg node_name "$server" -f templates/server.jq \
    > "consul_server/config/$server/config.json"
done