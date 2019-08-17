#!/usr/bin/env bash

set -exu

[[ -f docker-compose.yml ]] || {
  echo "Please run me from dir with docker-compose.yml"
  exit 1
}

. scripts/vars.bash

mkdir -p "$consul_poc_root/acls/policy/"
for agent in "${primary_dc_agent_names[@]}" "${secondary_dc_agent_names[@]}" "${client_names[@]}"; do
  cat <<NODE_POLICY > "$consul_poc_root/acls/policy/${agent}.hcl"
node "${agent}" {
  policy = "write"
}
service_prefix "" {
  policy = "read"
}
# DNS related rules
node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
NODE_POLICY
done; unset agent

for agent in "${secondary_dc_agent_names[@]}"; do
  cat <<NODE_POLICY >> "$consul_poc_root/acls/policy/${agent}.hcl"
# Rules for ACL replication
# Should be set to write if enable_token_replication is set true
acl = "read"
NODE_POLICY
done; unset agent

for agent in "${primary_dc_agent_names[@]}" "${secondary_dc_agent_names[@]}" "${client_names[@]}"; do
  if docker exec -it "consul_${agent[0]}_1" \
    /bin/sh -c '[ -f /consul/config/acl-tokens.json ]'; then
    echo "Token already created for $agent"
    continue
  fi
  echo "Creating token for $agent"
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${primary_dc_agent_names[0]}_1" \
    consul acl policy create \
      -name "$agent" \
      -description "$agent node write policy" \
      -rules "$(cat "$consul_poc_root/acls/policy/${agent}.hcl")"
  secret=$(uuidgen)
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${primary_dc_agent_names[0]}_1" \
    consul acl token create \
      -description "$agent agent token" \
      -secret "$secret" \
      -policy-name "$agent"
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${agent}_1" \
    consul acl set-agent-token agent "$secret"
done; unset agent

for policy in operator_ro operator_rw; do
  secret_var_name="${policy}_token"
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${primary_dc_agent_names[0]}_1" \
    consul acl policy create \
      -name "$policy" \
      -description "$policy policy" \
      -rules "$(cat "$consul_poc_root/templates/${policy}.hcl")"
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${primary_dc_agent_names[0]}_1" \
    consul acl token create \
      -description "$policy token" \
      -secret "${!secret_var_name}" \
      -policy-name "$policy"
done; unset policy