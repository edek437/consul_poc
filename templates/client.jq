{
  "client_addr": "0.0.0.0",
  "datacenter": $datacenter,
  "data_dir": "/consul/data/",
  "encrypt": $gossip_encryption_key,
  "log_level": "DEBUG",
  "enable_syslog": false,
  "enable_debug": true,
  "node_name": $node_name,
  "server": false,
  "leave_on_terminate": false,
  "skip_leave_on_interrupt": true,
  "rejoin_after_leave": true,
  "retry_join": $servers_to_join
}