#!/bin/bash -l

#the above line should ensure that enviroment variables are picked up (/.bashrc or maybe /.profile)

export DOCKER_SCAN_SUGGEST=false

stop_timeout=10
echo stop_timeout=$stop_timeout
need_build=false
need_start=false 
need_pull=false
option1="$1"
option2="$2"
set -e; 

function echo_title {
  line=$(echo "$1" | sed -r 's/./-/g')
  printf "\n$line\n$1\n$line\n\n"
}

function has_option {
  if [ "$option1" == "$1" ] || [ "$option2" == "$1" ] ||
     [ "$option1" == "$2" ] || [ "$option2" == "$2" ] ; then
    echo "true"
  else
    echo "false"
  fi
}
# goto script directory
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" > /dev/null

tag=$(cat Dockerfile | grep -oP 'cicd="\K\w+' | tail -1)
echo_title tag=$tag
if [ -z "$tag" ] ; then
  printf "\nNo cicd LABEL found in Dockerfile.\n\n"
  exit 1
fi

if [ $(has_option "--force" "-f") == "true" ] ; then
  need_pull=true
else
  need_pull=$(git fetch --dry-run 2>&1)
fi
echo_title need_pull=$need_pull

if [ -n "$need_pull" ] ; then
  echo_title "PULLING LATEST SOURCE CODE"
  git reset --hard
  git pull
  git log --pretty=oneline -1
  need_build=true
elif [ -z "$(docker images | grep "$tag" || true)" ] ; then
  need_build=true
fi
echo_title need_build=$need_build

status=$(docker ps | grep -w $tag | grep -E "Up|running" || true)
echo_title status=$status

#we want to STOP and RESTART the container even if no rebuild was done
#if [ "$need_build" == "true" ] ; then
  if [ ! -z "$status" ] ; then
    containerid=$(echo $status | grep -oP "^\S+")
    echo_title containerid=$containerid
    echo_title "STOPPING RUNNING CONTAINER containerid=$containerid"    
    docker stop $containerid -t $stop_timeout
    sleep 2 #wait a couple of seconds
    #remove container 
    docker rm $containerid
    sleep 1
  fi
  docker ps -q --filter "name=$tag" | grep -q . && docker stop $tag && docker rm -fv $tag
  #alternative command that produces a warning/'error', but works just fine
  #docker stop $tag || true && docker rm $tag || true
  need_start=true
#elif [ -z "$status" ] ; then
#  need_start=true
#fi

cfgfolder="/volume1/data/configs"
echo_title cfgfolder=$cfgfolder

echo_title need_start=$need_start
if [ "$need_start" == "false" ] ; then
  printf "\nNo changes found. Container is already running.\n"
elif [ "$need_build" == "true" ]; then
  echo_title "BUILDING CONTAINER"  
  #export tag=qbittorrentstats
  #docker build . -t $tag #NO ARGUMENTS
  docker build . --build-arg INFLUXDB_URL=$INFLUXDB_URL --build-arg INFLUXDB_ORG=$INFLUXDB_ORG --build-arg INFLUXDB_TOKEN=$INFLUXDB_TOKEN --build-arg QBITTORRENT_PASSWORD=$QBITTORRENT_PASSWORD -t $tag
fi

if [ "$need_start" == "true" ] ; then
  echo_title "STARTING CONTAINER"
  docker ps -a -q --filter "name=$tag" | grep -q . && docker rm -fv $tag
  docker run -d --restart unless-stopped -v /volume1/data:/volume1/data:rw -v $cfgfolder:/cfgfolder:ro -t --name $tag $tag #name sets the container name to run, tag references the image name, the last '$tag' is the image name to be run
fi

echo_title "Cleaning up --filter "label=cicd=$tag""
docker image prune --force --filter "label=cicd=$tag"

echo_title "Cleaning up docker system (docker image prune -a -f)"
docker image prune -a -f
echo_title "Cleaning up docker system (docker container prune -f)"
docker container prune -f 
echo_title "Cleaning up docker system (docker system prune -f)"
docker system prune -f


if [ $(has_option "--full_cleanup" "-fcu") == "true" ] ; then
  echo_title "FULL CLEAN-UP"
  docker image prune --force
elif [ $(has_option "--cleanup" "-cu") == "true" ] ; then
  echo_title "CLEAN-UP"
  docker image prune --force --filter "label=cicd=$tag"
fi

echo ""