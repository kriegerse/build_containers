#!/usr/bin/env bash

# HELPER VARS
SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)
MAXCOUNT=60
SLEEPTIME=5
GALERA1="galera-node1"
GALERA2="galera-node2"
GARBD1="garbd-node1"
DOCKER_IMAGE="garbd-stage"

# If not in CI use latest from production
if [[ ! "${CI}" == "true"  ]]; then
  docker_username="kriegerse"
  DOCKER_IMAGE="garbd"
  BUILD_PRIMARY_TAG="latest"
  kriegerse/garbd-stage:commit-8990da84
fi

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
    docker exec -t ${CONTAINER} mysql -u ${DBUSER} --password=${DBPASSWD} -e "SELECT 1;" > /dev/null
    RESULT=$?
    if [[ ${RESULT} -eq 0 ]]; then
      echo "Reached MariaDB Server"
      break
    elif [[ ${COUNT} -eq ${MAXCOUNT} ]]; then
      echo "Did no reach MariaDB Server ${CONTAINER}"
      echo "after $(( MAXCOUNT * SLEEPTIME )) seconds!"
      echo "FAILED!"
      exit 1
    else
      echo "Waiting for MariaDB Server ${CONTAINER} ready..."
    fi

    COUNT=$(( COUNT + 1 ))
    sleep ${SLEEPTIME}
  done
}


# fetch docker images
echo "========================================================================="
echo "Pulling docker images"
echo "========================================================================="
echo "* Image: mariadb:latest"
docker pull mariadb:latest
echo "* Image: ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}"
docker pull ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}


echo "========================================================================="
echo "Create network for galera cluster communication"
echo "========================================================================="
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
docker exec -t ${GALERA1} mysql -u root --password=my-secret-pw \
-e "CREATE USER 'mariabackup'@'localhost' IDENTIFIED BY 'mypassword';"
docker exec -t ${GALERA1} mysql -u root --password=my-secret-pw \
-e "GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'mariabackup'@'localhost';"
docker exec -t ${GALERA1} mysql -u root --password=my-secret-pw \
-e "FLUSH PRIVILEGES;"
docker exec -t ${GALERA1} mysql -u root --password=my-secret-pw \
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
wait_mysqld_ready "${GALERA2}" "root" "my-secret-pw"

# show privs for replication from node2
docker exec -t ${GALERA2} mysql -u root --password=my-secret-pw \
-e "SHOW GRANTS for 'mariabackup'@'localhost';"



# 3rd terminate galera-node1
echo "* Shutdown bootstrap helper node ${GALERA1}"
docker exec -t ${GALERA1} mysql -u root --password=my-secret-pw \
-e "shutdown;"
docker rm  -fv ${GALERA1}
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
wait_mysqld_ready "${GALERA1}" "root" "my-secret-pw"

echo "* Galera Cluster Ready!"


################################################################################
echo "========================================================================="
echo "TEST: JOIN ${GARBD1} to Galera Cluster"
echo "========================================================================="

echo "* Starting Galera Arbitor ${GARBD1}"
docker run -P --hostname ${GARBD1} --name ${GARBD1} --network galera-cluster \
  -e GALERA_GROUP=garbd_test \
  -e GALERA_NODES=${GALERA1}:4567,${GALERA2}:4567 \
  -dt ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}
sleep 10

echo "* Check number of Cluster members on each galera node (expecting size 3)"
for i in ${GALERA1} ${GALERA2}; do
  echo "* Processing ${i}"
  RESULT=$(docker exec ${i} mysql -u root --password=my-secret-pw \
  -e "show global status like 'wsrep_cluster_size';" --skip-column-names \
  --silent | awk '{print $2}')

  if [[ ${RESULT} -eq 3  ]]; then
    echo "OKAY: the cluster has ${RESULT} members."
  else
    echo "ERROR: the cluster does not have 3 members, seen ${RESULT}"
    exit 1
  fi
done

echo "========================================================================="
echo "TEST: REMOVE ${GARBD1} from Galera Cluster"
echo "========================================================================="

echo "* Stoping Galera Arbitor ${GARBD1}"
docker stop ${GARBD1}
sleep 10

echo "* Check number of Cluster members on each galera node (expecting size 2)"
for i in ${GALERA1} ${GALERA2}; do
  echo "* Processing ${i}"
  RESULT=$(docker exec ${i} mysql -u root --password=my-secret-pw \
  -e "show global status like 'wsrep_cluster_size';" --skip-column-names \
  --silent | awk '{print $2}')

  if [[ ${RESULT} -eq 2  ]]; then
    echo "OKAY: the cluster has ${RESULT} members."
  else
    echo "ERROR: the cluster does not have 2 members, seen ${RESULT}"
    exit 1
  fi
done


echo "========================================================================="
echo "TEST: REJOIN ${GARBD1} to Galera Cluster"
echo "========================================================================="

echo "* Restart Galera Arbitor ${GARBD1}"
docker start ${GARBD1}
sleep 10
echo "* Check number of Cluster members on each galera node (expecting size 3)"
for i in ${GALERA1} ${GALERA2}; do
  echo "* Processing ${i}"
  RESULT=$(docker exec ${i} mysql -u root --password=my-secret-pw \
  -e "show global status like 'wsrep_cluster_size';" --skip-column-names \
  --silent | awk '{print $2}')

  if [[ ${RESULT} -eq 3  ]]; then
    echo "OKAY: the cluster has ${RESULT} members."
  else
    echo "ERROR: the cluster does not have 3 members, seen ${RESULT}"
    exit 1
  fi
done

echo "========================================================================="
echo "TEST: REMOVE ${GALERA2} from Galera Cluster"
echo "========================================================================="

echo "* Stop Galera Node ${GALERA2}"
docker stop ${GALERA2}
sleep 10

echo "* Check number of Cluster members on last ${GALERA1} (expecting size 2)"
for i in ${GALERA1}; do
  echo "* Processing ${i}"
  RESULT=$(docker exec ${i} mysql -u root --password=my-secret-pw \
  -e "show global status like 'wsrep_cluster_size';" --skip-column-names \
  --silent | awk '{print $2}')

  if [[ ${RESULT} -eq 2  ]]; then
    echo "OKAY: the cluster has ${RESULT} members."
  else
    echo "ERROR: the cluster does not have 2 members, seen ${RESULT}"
    exit 1
  fi
done
