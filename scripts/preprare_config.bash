#!/usr/bin/env bash

set -eu

if [[ ${DEBUG:-} == true ]]; then
  set -x
fi

[[ -f docker-compose.yml ]] || {
  echo "Please run me from dir with docker-compose.yml"
  exit 1
}

. scripts/vars.bash

mkcd() {
  mkdir -p "$1" && cd "$1"
}

for dc_servers in "${servers_to_join[@]}"; do
  retry_join_wan=$(jq --argjson dcs "$dc_servers" '. + $dcs' <<< "$retry_join_wan")
done

echo "Generating CLI tokens"
for dc in "${!servers_to_join[@]}"; do
  (
    mkcd "$consul_poc_root/target_certs/consul-$dc"
    echo '{"key":{"algo":"rsa","size":2048}}' \
    | cfssl gencert \
      -ca="$ssl_dir/ca.pem" \
      -ca-key="$ssl_dir/ca-key.pem" \
      -profile=consul - | cfssljson -bare cli
  )
done; unset dc

echo "Generating client certificates"
for client in "${client_names[@]}"; do
  mkdir -p "$consul_poc_root/target_config/$client"
  dc=${client#consul-}
  dc=${dc%%-*}
  jq -n -e --arg gossip_encryption_key "$gossip_encryption_key" \
     --arg datacenter "$dc" \
     --arg node_name "$client" \
     --argjson servers_to_join "${servers_to_join["$dc"]}" \
     -f "$consul_config_dir/client.jq" \
   > "$consul_poc_root/target_config/$client/config.json"
  (
    mkcd "$consul_poc_root/target_certs/$client"
    jq -n -e --arg cn "$client" -f "$ssl_dir/client-crs.jq" \
     > client.json
    cfssl gencert -ca="$ssl_dir/ca.pem" \
      -ca-key="$ssl_dir/ca-key.pem" \
      -config="$ssl_dir/ca-config.json" \
      -profile=consul 'client.json' | cfssljson -bare client
    # consul in container has uid(100) and guid(1000) and my user has uid(1000) guid(1000)
    # so this is hack to give consul user perms to certs without using `sudo chown`
    chmod g+rw *
  )
done; unset client dc

echo "Generating server certificates"
for server in "${primary_dc_agent_names[@]}" "${secondary_dc_agent_names[@]}"; do
  mkdir -p "$consul_poc_root/target_config/$server"
  dc=${server#consul-}
  dc=${dc%%-*}
  jq -n -e --arg gossip_encryption_key "$gossip_encryption_key" \
     --arg primary_datacenter "$primary_datacenter" \
     --arg datacenter "$dc" \
     --arg node_name "$server" \
     --argjson retry_join_wan "${retry_join_wan[@]}" \
     --argjson servers_to_join "${servers_to_join["$dc"]}" \
     -f "$consul_config_dir/server.jq" \
   > "$consul_poc_root/target_config/$server/config.json"
  (
    mkcd "$consul_poc_root/target_certs/$server"
    jq -n -e --arg cn "$server" \
       --argjson hosts "[\"127.0.0.1\",\"localhost\", \"$server\", \"server.$dc.consul\"]" \
       -f "$ssl_dir/server-crs.jq" \
     > server.json
    cfssl gencert -ca="$ssl_dir/ca.pem" \
      -ca-key="$ssl_dir/ca-key.pem" \
      -config="$ssl_dir/ca-config.json" \
      -profile=consul 'server.json' | cfssljson -bare server
    # consul in container has uid(100) and guid(1000) and my user has uid(1000) guid(1000)
    # so this is hack to give consul user perms to certs without using `sudo chown`
    chmod g+rw *
  )
done; unset server dc

echo "Preparing master and replication tokens."
for agent in "${primary_dc_agent_names[@]}"; do
  jq -n -e --arg master_token "$master_token" \
    -f "$acl_dir/master_token.jq" \
    > "$consul_poc_root/target_config/$agent/master_token.json"
done; unset agent

for agent in "${secondary_dc_agent_names[@]}"; do
  jq -n -e --arg replication_token "$replication_token" \
    -f "$acl_dir/replication_token.jq" \
    > "$consul_poc_root/target_config/$agent/replication_token.json"
done; unset agent