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
# wait a moment
./scripts/prepare_acls.bash
# ACL policies are enabled
```

TODO:
- [x] make single cluster setup work with 2 agents
- [x] multi DC setup (3DCs, dc1 with 2 agents, dc2 and dc3 with 1 agent)
- [x] gossip protocol encryption
- [x] migrate from http to https (including CLI)
- [ ] set up ACL
- [ ] research ACLs and UI access (or consul behind auth proxy??)
- [ ] research consul-replicate for kv state replication??
- [ ] add basic infra checks (maybe nagios/other monitoring framework or custom ones)
- [ ] research adding watches to KV for auditing changes
- [ ] research Consul servers behind nginx/haproxy
- [ ] reaserch using Consul watches/events/kv as message queue