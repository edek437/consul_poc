{
  "bind_addr": "0.0.0.0", 
  "datacenter": "dc1",
  "data_dir": "/consul/data/",
  "log_level": "DEBUG",
  "enable_syslog": false,
  "enable_debug": true,
  "node_name": $node_name,
  "server": false,
  "leave_on_terminate": false,
  "skip_leave_on_interrupt": true,
  "rejoin_after_leave": true,
  "retry_join": [ 
    "172.16.0.11",
    "172.16.0.12",
    "172.16.0.13"
  ]
}