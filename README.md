Prerequisistes
---
1. Linux machine
1. Installed: jq (v1.6), cfssl, cfssljson, docker (17.09.0+), docker-compose

Directory structure
---
```
config  
|- acl - ACL configuration and policies  
|- consul - Consul agents congiration files and jq templates  
|- env - environment variables for docker containers  
|- ssl - SSL self-signed CA certificates and cfssl input files  
scripts  
|- vars.sh - common variables shared between scripts  
|- prepare_config.sh - based on templates in config directory genarates  
|                     target configuration files and certificates for agents  
|- prepare_acls.sh - based on templates in config directory genarates ACL  
                     rules and token and pr  
docker-compose.yml - Consul multi DC containers configuration
target_* - configuration files and certificates prepared by prepare_config.sh
```
Setup
---

```bash
./scripts/prepare_config.bash
docker-compose up -d
# 3 DC cluster is up and running
# wait a moment
./scripts/prepare_acls.bash
# ACL policies are enabled
# Occassionally prepare_acls.bash will abort on when setting token  
# returns 403. In such case please rerun script.

#And when you finish
docker-compose down
```

TODO:
- [x] make single cluster setup work with 2 agents
- [x] multi DC setup (3DCs, dc1 with 2 agents, dc2 and dc3 with 1 agent)
- [x] gossip protocol encryption
- [x] migrate from http to https (including CLI)
- [x] set up ACL
- [x] research ACLs and UI access (or consul behind auth proxy??)
- [x] Fix bug where docker-dompose down before up is required to ensure cluster is working (due to invalid config key agent error)
- [ ] add basic infra checks (maybe nagios/other monitoring framework or custom ones)
- [ ] research adding watches to KV for auditing changes
- [ ] research consul-replicate for kv state replication between DCs (or uses waches since consul-replicate seems no longer maintained)
- [ ] reaserch using Consul watches/events/kv as message queue
- [ ] reaserch predefined queries as fallback for DC failures
- [ ] add KV backups and backup restoration (snapshot ecluded since every new run is new containers hence different server)
- [ ] research Consul servers behind nginx/haproxy
- [ ] reasearch what happen if primary DC is down