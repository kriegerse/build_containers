# BoringTun - openSUSE_Leap based

An openSUSE Leap based BoringTun docker image.
[BoringTun](https://blog.cloudflare.com/boringtun-userspace-wireguard-rust/) is
a [wireguard](https://www.wireguard.com) userspace implementation from
Cloudflare implemented in Rust.

Userspace tools like `wg-quick`and `wg` come from openSUSE Build Service
`obs://network:vpn:wireguard wireguard` https://download.opensuse.org/repositories/network:/vpn:/wireguard/openSUSE_Leap_15.1.

## Connectivity

The container does not expose any port by default, but can be configured by
your orchestrator or what ever you use to run the container.

Since the container needs to create a tun interface it must be started with
`--cap-add=NET_ADMIN` privileges and the hosts `--device /dev/net/tun:/dev/net/tun` must be reached into the container.

## Persistency

Configurations are stored in `/etc/wireguard`. To not loose any config
a volume can be mounted to this location persisting the same.

```
docker run --cap-add=NET_ADMIN \
   --d device /dev/net/tun:/dev/net/tun \
   -v etc_wireguard:/etc/wireguard \
   boringtun:latest  
```


## Configuration


Per default the container is expecting a configuration file `wg0.conf` in the config directory `/etc/wireguard`.

```
docker run --cap-add=NET_ADMIN \
   --d device /dev/net/tun:/dev/net/tun \
   -v etc_wireguard:/etc/wireguard \
   boringtun:latest  
```

Other device names can be submitted, but must start with `wg`.

```
docker run --cap-add=NET_ADMIN \
   --d device /dev/net/tun:/dev/net/tun \
   -v etc_wireguard:/etc/wireguard \
   boringtun:latest wg-usefule-name
```

## Debugging

For debugging purpose or own start scripts the container can started with any other command.

```
docker run --cap-add=NET_ADMIN \
   --d device /dev/net/tun:/dev/net/tun \
   -v etc_wireguard:/etc/wireguard \
   -it boringtun:latest /bin/bash
```
