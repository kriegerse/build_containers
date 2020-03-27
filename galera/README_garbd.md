# Galera ArbiArbitratorter (garbd) - openSUSE_Leap based

An openSUSE Leap based docker image including the official
[MariaDB yum repository](https://yum.mariadb.org/).

## Connectivity

The container exposes port 4567, the standard Galera Cluster replication port.

## Configuration

The container uses the `garb-systemd` helper script making use of environment
variables set or read from /etc/sysconfig/garb.

When starting the container you can either use a bind mount a proper config
file:
```
docker run -P -it --rm -v /tmp/garb.example:/etc/sysconfig/garb \
kriegerse/garbd:latest
```

or set environment variables:
* `GALERA_NODES` - A comma-separated list of node addresses (address[:port]) in
the cluster
* `GALERA_GROUP` - the name of the galera gluster group,should be the same as on
the rest of the nodes.
* `GALERA_OPTIONS` - Optional Galera internal options string (e.g. SSL settings)
* `LOG_FILE` - Log file for garbd. Optional, by default logs to syslog (STDOUT)

```
docker run -P -it \
-e GALERA_GROUP=<my_gluster_name> \
-e GALERA_NODES=<DB-NODE1-IP>:4567,<DB-NODE2-IP>:4567 \
kriegerse/garbd:latest
```
