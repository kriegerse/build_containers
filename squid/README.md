# squid - openSUSE_Leap based

An openSUSE Leap based squid docker image.


## Connectivity

The container exposes the squid default port 3128.


## Persistency

If required a volume can be bind mounted to `/var/cache/squid` where the caching
directory is located by default (see ENV variable `SQUID_CACHE_DIR`).

```
docker run \
   -v squid_cache:/var/cache/squid \
   kriegerse/squid:latest  
```


## Configuration

There are a couple of environment variables to be set for configuring the squid
cache location.

```
SQUID_CACHE_DIR=/var/cache/squid
SQUID_CACHE_ENGINE=aufs
SQUID_CACHE_SIZE=1000
SQUID_MAX_OBJECT_SIZE=512
SQUID_CONF=/etc/squid/squid.conf
```

Set `SQUID_CACHE_DIR=""` if you want to disable the cache.

If you want to run your own configuring you can bind mount the same to the
location set in environment variable `SQUID_CONF`.


## Debugging

For debugging purpose or own start scripts the container can started with any other command.

```
docker run -it kriegerse/squid:latest /bin/bash
```
