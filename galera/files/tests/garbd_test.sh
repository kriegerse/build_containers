#!/usr/bin/env bash

set -x

# HELPER VARS
SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)
MAXCOUNT=60
SLEEPTIME=5
GALERA1="galera-node1"
GALERA2="galera-node2"
GARBD1="garbd-node1"

# HELPER FUNCTIONS
### wait_mysqld_ready ###############
# Desc: checks if mysqld is ready for answering queries
# Params: $1 - dockercontainer to check
#         $2 - mysql user
#         $3 - mysql password
function wait_mysqld_ready {
  COUNT=1
  CONTAINER=$1
  DBUSER=$2
  DBPASSWD=$3

  while [ ${COUNT} -lt $MAXCOUNT ]; do
    docker exec -it ${CONTAINER} mysql -u ${DBUSER} --password=${DBPASSWD} -e "SELECT 1;" > /dev/null
    RESULT=$?
    if [[ ${RESULT} -eq 0 ]]; then
      echo "Reached MariaDB Server"
      break
    elif [[ ${COUNT} -eq ${MAXCOUNT} ]]; then
      echo "Did no reach MariaDB Server"
      echo "after $(( MAXCOUNT * SLEEPTIME )) seconds!"
      echo "FAILED!"
      exit 1
    else
      echo "Waiting for MariaDB Server ready"
    fi

    COUNT=$(( COUNT + 1 ))
    sleep ${SLEEPTIME}
  done
}


# fetch docker images
docker pull mariadb:latest
docker pull ${docker_username}/garbd-stage:${BUILD_PRIMARY_TAG}

# create network for galera cluster communication
docker network create galera-cluster
docker network ls

################################################################################
echo "========================================================================="
echo "Bootstrap Galera Cluster"
echo "========================================================================="

echo "* Start Node ${GALERA1} (bootstrap mode)"
docker run -P -v ${SCRIPTPATH}/galera_my.cnf:/etc/mysql/my.cnf \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  --hostname ${GALERA1} \
  --name ${GALERA1} \
  --network galera-cluster \
  -dt mariadb:latest \
  mysqld --wsrep-new-cluster

# wait until mysqld is ready
wait_mysqld_ready "${GALERA1}" "root" "my-secret-pw"

# set privs for replication
echo "* Setting privileges for galaera replication"
docker exec -it ${GALERA1} mysql -u root --password=my-secret-pw \
-e "CREATE USER 'mariabackup'@'localhost' IDENTIFIED BY 'mypassword';"
docker exec -it ${GALERA1} mysql -u root --password=my-secret-pw \
-e "GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'mariabackup'@'localhost';"
docker exec -it ${GALERA1} mysql -u root --password=my-secret-pw \
-e "FLUSH PRIVILEGES;"
docker exec -it ${GALERA1} mysql -u root --password=my-secret-pw \
-e "SHOW GRANTS for 'mariabackup'@'localhost';"


# 2nd join galera-node2
echo "* Start Node ${GALERA2}"
docker run -P -v ${SCRIPTPATH}/galera_my.cnf:/etc/mysql/my.cnf \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  --hostname ${GALERA2} \
  --name ${GALERA2} \
  --network galera-cluster \
  -dt mariadb:latest \
  /bin/bash -c 'su - mysql -c  mysql_install_db; mysqld -u mysql'

# loop until mysqld is ready
wait_mysqld_ready "galera-node2" "root" "my-secret-pw"

# show privs for replication from node2
docker exec -it ${GALERA2} mysql -u root --password=my-secret-pw \
-e "SHOW GRANTS for 'mariabackup'@'localhost';"

# 3rd terminate galera-node1
echo "* Shutdown bootstrap helper node ${GALERA1}"
docker exec -it galera-node1 mysql -u root --password=my-secret-pw \
-e "shutdown;"

docker rm  -fv galera-node1
sleep 10


# 4th start + join production galera-node1
echo "* (re)Start Node ${GALERA1}"
docker run -P -v ${SCRIPTPATH}/galera_my.cnf:/etc/mysql/my.cnf \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  --hostname galera-node1 \
  --name galera-node1 \
  --network galera-cluster \
  -dt mariadb:latest \
  /bin/bash -c 'su - mysql -c  mysql_install_db; mysqld -u mysql'

# loop until mysqld is ready
wait_mysqld_ready "galera-node1" "root" "my-secret-pw"

echo "* Galera Cluster Ready!"


################################################################################
echo "========================================================================="
echo "Join GARBD"
echo "========================================================================="

echo "* Starting Galera Arbitor ${GARBD1}"
docker run -P --hostname ${GARBD1} --name ${GARBD1} --network galera-cluster \
  -e GALERA_GROUP=garbd_test \
  -e GALERA_NODES=${GALERA1}:4567,${GALERA2}:4567 \
  -dt ${docker_username}/garbd-stage:${BUILD_PRIMARY_TAG}
