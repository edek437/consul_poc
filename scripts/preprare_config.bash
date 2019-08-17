#!/usr/bin/env bash

set -exu

[[ -f docker-compose.yml ]] || {
  echo "Please run me from dir with docker-compose.yml"
  exit 1
}

. scripts/vars.bash

for dc_servers in "${servers_to_join[@]}"; do
  retry_join_wan=$(jq --argjson dcs "$dc_servers" '. + $dcs' <<< "$retry_join_wan")
done

for dc in "${!servers_to_join[@]}"; do
  (
    mkdir -p "consul_server/certs/consul-$dc"
    cd "consul_server/certs/consul-$dc"
    echo '{"key":{"algo":"rsa","size":2048}}' \
    | cfssl gencert \
      -ca="$consul_poc_root/templates/ca.pem" \
      -ca-key="$consul_poc_root/templates/ca-key.pem" \
      -profile=client - | cfssljson -bare cli
  )
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
    cfssl gencert -ca="$consul_poc_root/templates/ca.pem" \
      -ca-key="$consul_poc_root/templates/ca-key.pem" \
      -config="$consul_poc_root/templates/ca-config.json" \
      -profile=client 'client.json' | cfssljson -bare client
    # consul in container has uid(100) and guid(1000) and my uer has uid(1000) guid(1000)
    # so this is hack to give consul user perms to certs without sudo chown
    chmod g+rw *
  )
done; unset client dc

for server in "${primary_dc_agent_names[@]}" "${secondary_dc_agent_names[@]}"; do
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
    cfssl gencert -ca="$consul_poc_root/templates/ca.pem" \
      -ca-key="$consul_poc_root/templates/ca-key.pem" \
      -config="$consul_poc_root/templates/ca-config.json" \
      -profile=server 'server.json' | cfssljson -bare server
    # consul in container has uid(100) and guid(1000) and my uer has uid(1000) guid(1000)
    # so this is hack to give consul user perms to certs without sudo chown
    chmod g+rw *
  )
done; unset server dc

for agent in "${primary_dc_agent_names[@]}"; do
  jq -n -e --arg master_token "$master_token" \
    -f "$consul_poc_root/templates/acl_master_token.jq" \
    > "$consul_poc_root/consul_server/config/$agent/master_token.json"
done; unset agent

for agent in "${secondary_dc_agent_names[@]}"; do
  jq -n -e --arg replication_token "$replication_token" \
    -f "$consul_poc_root/templates/acl_replication_token.jq" \
    > "$consul_poc_root/consul_server/config/$agent/replication_token.json"
done; unset agent