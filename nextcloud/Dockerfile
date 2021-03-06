ARG NC_VERSION='21'

FROM nextcloud:${NC_VERSION}
ARG FS_BASE=''

COPY ./${FS_BASE}/files  /usr/local/.
RUN bash /usr/local/bin/prepare_container.sh
