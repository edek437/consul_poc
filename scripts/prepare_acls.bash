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

docker_on() {
  local container_name=$1
  shift
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "$container_name" "$@"
}

echo "Preparing policies"
mkdir -p "$consul_poc_root/target_acls/policy/"
for agent in "${client_names[@]}"; do
  sed "s/{%node_name%}/$agent/" "$policies_dir/agent_policy.hcl.tpl" \
    > "$consul_poc_root/target_acls/policy/${agent}.hcl"
done; unset agent

for agent in "${primary_dc_agent_names[@]}" "${secondary_dc_agent_names[@]}"; do
  sed "s/{%node_name%}/$agent/" "$policies_dir/server_policy.hcl.tpl" \
    > "$consul_poc_root/target_acls/policy/${agent}.hcl"
done; unset agent

echo "Propagating policies to nodes"
for agent in "${primary_dc_agent_names[@]}" "${secondary_dc_agent_names[@]}" "${client_names[@]}"; do
  if docker_on "consul_${agent[0]}_1" \
    /bin/sh -c '[ -f /consul/config/acl-tokens.json ]'; then
    echo "Token already created for $agent"
    continue
  fi
  echo "Creating token for $agent"
  token_desc="$agent node write policy"
  if docker_on "consul_${primary_dc_agent_names[0]}_1" \
    consul acl policy list | grep "$token_desc" > /dev/null; then
    echo "Policy for $agent already exists."
  else
    docker_on "consul_${primary_dc_agent_names[0]}_1" \
      consul acl policy create \
        -name "$agent" \
        -description "$token_desc" \
        -rules "$(cat "$consul_poc_root/target_acls/policy/${agent}.hcl")"
  fi
  secret=$(uuidgen)
  docker_on "consul_${primary_dc_agent_names[0]}_1" \
    consul acl token create \
      -description "$agent agent token" \
      -secret "$secret" \
      -policy-name "$agent"
  docker_on "consul_${agent}_1" \
    consul acl set-agent-token agent "$secret"
done; unset agent token_desc secret

echo "Applying operator ACLs"
for policy in operator_ro operator_rw; do
  secret_var_name="${policy}_token"
  if docker_on "consul_${primary_dc_agent_names[0]}_1" \
    consul acl policy list | grep "$policy policy" > /dev/null; then
    echo "Policy for $policy already exists."
  else
    docker_on "consul_${primary_dc_agent_names[0]}_1" \
      consul acl policy create \
        -name "$policy" \
        -description "$policy policy" \
        -rules "$(cat "$policies_dir/${policy}.hcl")"
  fi
  if docker_on "consul_${primary_dc_agent_names[0]}_1" \
    consul acl token list | grep "$policy token" > /dev/null; then
    echo "Token for $policy already exists."
  else
    docker_on "consul_${primary_dc_agent_names[0]}_1" \
      consul acl token create \
        -description "$policy token" \
        -secret "${!secret_var_name}" \
        -policy-name "$policy"
  fi
done; unset policy secret_var_name