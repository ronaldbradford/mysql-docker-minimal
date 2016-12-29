#!/bin/sh

DOCKER_IMAGE_BASE="datacharmer/mysql-minimal-"
MYSQL_VOLUME_PREFIX="mysqlbin-"
MYSQL_VERSIONS="5.0 5.1 5.5 5.6 5.7 8.0" # https://github.com/datacharmer/mysql-docker-minimal
#OS_IMAGE="datacharmer/my-ubuntu"
OS_IMAGE="ronaldbradford/my-ubuntu:16.04"

docker_mysql_cleanup() {
  for VERSION in `echo ${MYSQL_VERSIONS}`
  do
    docker rmi ${DOCKER_IMAGE_BASE}${VERSION}
  done

  return 0
}

docker_mysql_setup () {
  local REQUESTED_VERSION=$1
  local VERSION

  [ -z "${REQUESTED_VERSION}" ] && REQUESTED_VERSION="${MYSQL_VERSIONS}"
  for VERSION in `echo ${REQUESTED_VERSION}`
  do
    if [ `docker images -q ${DOCKER_IMAGE_BASE}${VERSION} | wc -l` -eq 0 ]
    then
      echo "Obtaining Docker MySQL ${VERSION} image"
      docker pull ${DOCKER_IMAGE_BASE}${VERSION}
      RC=$?
      if [ ${RC} -ne 0 ]
      then
        echo "ERROR: [${RC}] Problem obtaining image for ${VERSION}"
        return ${RC}
      fi
    fi

    docker rm ${MYSQL_VOLUME_PREFIX}${VERSION} 2>/dev/null
    docker volume rm ${MYSQL_VOLUME_PREFIX}${VERSION} 2>/dev/null

    docker create --name ${MYSQL_VOLUME_PREFIX}${VERSION} -v /opt/mysql ${DOCKER_IMAGE_BASE}${VERSION}
    RC=$?
  done



  return 0
}

docker_mysql_init() {
   [ -z `which docker 2>/dev/null` ] && echo "ERROR: docker command not found." && return 1
   docker images > /dev/null
   RC=$?
   GROUP=`groups | grep "docker" | wc -l`
   [ ${RC} -ne 0 ] && echo "ERROR: Unable to run docker as user. docker group (${GROUP})" && return 2

   return 0
}

docker_mysql_run() {
  local VERSION=$1
  local CONTAINER_NAME

  [ -z "${VERSION}" ] && echo "ERROR: Specify a version to launch" && return 3
  CONTAINER_NAME="mysql${VERSION}"

  docker rm ${CONTAINER_NAME} 2>/dev/null
  docker run --rm -ti --volumes-from ${MYSQL_VOLUME_PREFIX}${VERSION} --name ${CONTAINER_NAME} ${OS_IMAGE} bash
  RC=$?
  [ ${RC} -eq 0 ] && docker rm ${CONTAINER_NAME} ${MYSQL_VOLUME_PREFIX}${VERSION} 2>/dev/null

  return ${RC}
}


docker_mysql() {
  local VERSION=$1

  [ -z "${VERSION}" ] && echo "ERROR: Specify a version to launch" && return 3
  [ `echo ${MYSQL_VERSIONS} | grep ${VERSION} | wc -l` -eq 0 ] && echo "ERROR: MySQL version ${VERSION} is not recognized" && return 4

  docker_mysql_setup ${VERSION}
  docker_mysql_run ${VERSION}
}

