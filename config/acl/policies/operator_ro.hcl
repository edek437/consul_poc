service_prefix "" {
  policy = "read"
}
key_prefix "" {
  policy = "read"
}

# Only if enable_key_list_policy is set to true
key_prefix "" {
  policy = "list"
}

node_prefix "" {
  policy = "read"
}