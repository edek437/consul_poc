{
  "client_addr": "0.0.0.0",
  "datacenter": $datacenter,
  "primary_datacenter": $primary_datacenter,
  "data_dir": "/consul/data/",
  "encrypt": $gossip_encryption_key,
  "log_level": "DEBUG",
  "enable_syslog": false,
  "enable_debug": true,
  "node_name": $node_name,
  "server": true,
  "ui": true,
  "bootstrap_expect": 3,
  "leave_on_terminate": false,
  "skip_leave_on_interrupt": true,
  "rejoin_after_leave": true,
  "retry_join": $servers_to_join,
  "retry_join_wan": $retry_join_wan
}