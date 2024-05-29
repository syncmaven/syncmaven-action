#!/usr/bin/env bash

env | grep SYNCMAVEN_

SYNC_ARGS=""
PROJECT_DIR="$GITHUB_WORKSPACE"

if [ ! -z $INPUT_DIR ]; then
  PROJECT_DIR="$PROJECT_DIR/$INPUT_DIR"
fi

if [ ! -z $INPUT_SELECT ]; then
  SYNC_ARGS="$SYNC_ARGS --select $INPUT_SELECT"
fi

if [ ! -z $INPUT_STATE ]; then
  SYNC_ARGS="$SYNC_ARGS --state $INPUT_STATE"
fi

if [ ! -z $INPUT_DEBUG ]; then
  SYNC_ARGS="$SYNC_ARGS --debug"
fi

if [ ! -z $INPUT_FULL ]; then
  SYNC_ARGS="$SYNC_ARGS --full-refresh"
fi

echo "PROJECT_DIR: $PROJECT_DIR"

ls -la $PROJECT_DIR

export RPC_PORT=8081

set -x

docker run -e RPC_PORT -p 8081:8081 -v /var/run/docker.sock:/var/run/docker.sock -v $PROJECT_DIR:/project syncmaven/syncmaven:latest sync $SYNC_ARGS
