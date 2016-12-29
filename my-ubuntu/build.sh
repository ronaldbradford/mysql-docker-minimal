#!/bin/sh

REPOSITORY="ronaldbradford/my-ubuntu"

run() {
  $*
  RC=$?
  [ ${RC} -ne 0 ] && echo "$1 $2 ... failed" && exit ${RC}
}

[ ! -s  ~/.docker/config.json ] && docker login


docker rmi -f $(docker images ${REPOSITORY} -q) 2>/dev/null

for VERSION in `ls -d [12]*`
do
  echo "Building ${REPOSITORY} version ${VERSION}"
  run cd ${VERSION}
  run cp ../docker-entrypoint.sh .
  
  run docker build -t my-ubuntu .
  IMAGE=`docker images my-ubuntu -q`
  run docker images ${REPOSITORY}:${VERSION}
  run docker tag ${IMAGE} ${REPOSITORY}:${VERSION}
  run docker images ${REPOSITORY}:${VERSION}
  run docker push ${REPOSITORY}
  run docker rmi -f ${IMAGE}
  run docker run --rm -ti ${REPOSITORY}:${VERSION} cat /etc/lsb-release
  run rm docker-entrypoint.sh
  run cd ..
done

docker images ${REPOSITORY}
