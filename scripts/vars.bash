#!/bin/false

declare cosul_poc_root=$PWD
declare ca_file='templates/ca.pem'
declare ca_key_file='templates/ca-key.pem'

declare gossip_encryption_key='VhPBrehv0113moXGHevkEA=='
declare primary_datacenter='dc1'
declare retry_join_wan='[]'

declare master_token='0587faf3-66e9-4081-b61c-4f55d16147b7'

declare -a client_names=(
  consul-dc1-agent-1
  consul-dc1-agent-2
  consul-dc1-agent-3
  consul-dc2-agent-1
  consul-dc3-agent-1
)

declare -a primary_dc_agent_names=(
  consul-dc1-server-1
  consul-dc1-server-2
  consul-dc1-server-3
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