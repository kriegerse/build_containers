# BoringTun - openSUSE_Leap based

An openSUSE Leap based BoringTun docker image.
[BoringTun](https://blog.cloudflare.com/boringtun-userspace-wireguard-rust/) is
a [wireguard](https://www.wireguard.com) userspace implementation from
Cloudflare implemented in Rust.

## Connectivity


## Persistency

Database and signatures goes to `/data/db` using the default configuration delivered by the repository above.

Idially those will be persisted with a volume:

```
docker run -P -d -v /data/db kriegerse/clamav:latest
```

## Configuration

Place individual configuration(s) in



```
docker run -P -it -v /clamav/conf/clamd.conf:/data/conf/clamd.conf  -v /clamav/conf/freshclam.conf:/data/conf/freshclam.conf kriegerse/clamav:latest
```
