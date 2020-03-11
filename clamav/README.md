# ClamAV - openSUSE_Leap based

An openSUSE Leap based ClamAV docker image including the [OpenSuse Security Tools](http://download.opensuse.org/repositories/security/) repository as suggested in the official https://www.clamav.net/downloads#otherversions docs.

## Connectivity

The container exposes port 3310 for TCP Stream and remote scans.

## Persistency

Database and signatures goes to `/data/db` using the default configuration delivered by the repository above.

Idially those will be persisted with a volume:

```
docker run -P -d -v /data/db kriegerse/clamav:latest
```

## Configuration

Place individual configuration(s) in
* clamav - `/data/conf/clamd.conf`
* freshclam - `/data/conf/freshclam.conf`

They will be picked up by the supervisord start scripts if exists.


```
docker run -P -it -v /clamav/conf/clamd.conf:/data/conf/clamd.conf  -v /clamav/conf/freshclam.conf:/data/conf/freshclam.conf kriegerse/clamav:latest
```
