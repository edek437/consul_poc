node "{%node_name%}" {
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
acl = "read"