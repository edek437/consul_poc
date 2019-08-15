Prerequisistes
---
1. Linux machine
1. Installed: jq (v1.6), cfssl, cfssljson, docker, docker-compose

Setup
---

```bash
./scripts/prepare_config.bash
docker-compose up -d
# 3 DC cluster is up and running
```

TODO:
- [x] make single cluster setup work with 2 agents
- [x] multi DC setup (3DCs, dc1 with 2 agents, dc2 and dc3 with 1 agent)
- [x] gossip protocol encryption
- [x] migrate from http to https (including CLI)
- [ ] set up ACL (or maybe LDAP integration??)
- [ ] research ACLs and UI access
- [ ] research consul-replicate for kv state replication??
- [ ] add basic infra checks (maybe nagios/other monitoring framework or custom ones)
- [ ] research adding watches to KV for auditing changes
- [ ] research Consul servers behind nginx/haproxy