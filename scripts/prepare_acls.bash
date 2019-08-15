#!/usr/bin/env bash

set -exu

[[ -f docker-compose.yml ]] || {
  echo "Please run me from dir with docker-compose.yml"
  exit 1
}

. scripts/vars.bash

mkdir -p "$cosul_poc_root/acls/policy/"
for agent in "${server_names[@]}" "${client_names[@]}"; do
  cat <<NODE_POLICY > "$cosul_poc_root/acls/policy/${agent}.hcl"
node "${agent}" {
  policy = "write"
}
NODE_POLICY
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${server_names[0]}_1" \
    consul acl policy create \
      -name "$agent" \
      -description "$agent node write policy" \
      -rules "$(cat "$cosul_poc_root/acls/policy/${agent}.hcl")"
  secret=$(uuidgen)
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${server_names[0]}_1" \
    consul acl token create \
      -description "$agent agent token" \
      -secret "$secret" \
      -policy-name "$agent"
  docker exec --env CONSUL_HTTP_TOKEN="$master_token" -it \
    "consul_${agent}_1" \
    consul acl set-agent-token agent "$secret"
done