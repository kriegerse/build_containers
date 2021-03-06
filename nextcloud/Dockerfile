ARG NC_VERSION='21'
ARG FS_BASE=''

FROM nextcloud:${NC_VERSION}

COPY ./${FS_BASE}/files  /usr/local/.
RUN bash /usr/local/bin/prepare_container.sh
