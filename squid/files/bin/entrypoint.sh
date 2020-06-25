#!/usr/bin/env bash

configure_cache_dir() {
  if [[ "${SQUID_CACHE_DIR}" != "" ]]; then
    echo "Configure Squid Cache Dir"
    echo "cache_dir ${SQUID_CACHE_ENGINE} ${SQUID_CACHE_DIR} ${SQUID_CACHE_SIZE} 16 256" >> ${SQUID_CONF}

    if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
      echo "Initializing cache... ${SQUID_CACHE_DIR}"
      squid -N -z -f ${SQUID_CONF}
    fi
  fi
}

configure_max_object_size() {
  echo "Configure Maximum Object Size"
  echo "maximum_object_size ${SQUID_MAX_OBJECT_SIZE} MB" >> ${SQUID_CONF}
}

configure_logging_stdout() {
  # allow logging to stdout/stderr for none root user
  chmod a+rw /dev/pts/0 /dev/stdout
  echo "logfile_rotate 0" >> ${SQUID_CONF}
  echo "cache_log stdio:/dev/stdout" >> ${SQUID_CONF}
  echo "access_log stdio:/dev/stdout" >> ${SQUID_CONF}
  echo "cache_store_log stdio:/dev/stdout" >> ${SQUID_CONF}
}

if [[ -z ${1} ]]; then
  configure_cache_dir
  configure_max_object_size
  configure_logging_stdout
  echo "Starting squid..."
  exec squid -f ${SQUID_CONF} --foreground -d 1
else
  exec "$@"
fi
