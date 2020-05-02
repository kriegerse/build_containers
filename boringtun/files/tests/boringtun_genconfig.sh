#!/usr/bin/env bash

SCRIPT=$(readlink -f $0)


# maske sure environment is set otherwise exit
if [[ ! -v WG0  || ! -v WG1 || ! -v WGVOLUMEMNT ]]; then
  echo "ERROR: ${SCRIPT} please make sure environment WG0, WG1, WGVOLUMEMNT is set"
  exit 1
fi


echo "* ${SCRIPT} Create keys"
echo "** ${SCRIPT} Generating keys for ${WG0}"
WG0PRIVATE=$(wg genkey)
WG0PUBLIC=$(echo ${WG0PRIVATE} | wg pubkey)

echo "** ${SCRIPT} Generating keys for ${WG1}"
WG1PRIVATE=$(wg genkey)
WG1PUBLIC=$(echo ${WG1PRIVATE} | wg pubkey)

echo "** ${SCRIPT} Generating PSK for ${WG0} <-> ${WG1} communication"
WGPSK=$(wg genpsk)

echo "* ${SCRIPT} Create config wg0.conf for ${WG0}"
cat <<EOF > ${WGVOLUMEMNT}/wg0.conf
[Interface]
PrivateKey = ${WG0PRIVATE}
# Address = 10.0.0.1/24,fd42:42:42::1/64
Address = 10.0.0.1/24
ListenPort = 11234

[Peer]
PublicKey = ${WG1PUBLIC}
PresharedKey = ${WGPSK}
# AllowedIPs = 10.0.0.2/32,fd42:42:42::2/128
AllowedIPs = 10.0.0.2/32

EOF


echo "* ${SCRIPT} Create config wg1.conf for ${WG1}"
cat <<EOF > ${WGVOLUMEMNT}/wg1.conf
[Interface]
PrivateKey = ${WG1PRIVATE}
# Address = 10.0.0.2/24,fd42:42:42::2/64
Address = 10.0.0.2/24


[Peer]
PublicKey = ${WG0PUBLIC}
PresharedKey = ${WGPSK}
# AllowedIPs = 10.0.0.1/32,fd42:42:42::1/128
AllowedIPs = 10.0.0.1/32
Endpoint = ${WG0}:11234
PersistentKeepalive = 5

EOF
