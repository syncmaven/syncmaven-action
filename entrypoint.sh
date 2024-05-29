#!/usr/bin/env bash

awk 'BEGIN{for(v in ENVIRON) print v}' > .env

SYNC_ARGS=""

REPOSITORY=$(echo "${RUNNER_WORKSPACE##*/}")

PROJECT_DIR="$RUNNER_WORKSPACE/$REPOSITORY"

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

export RPC_PORT=8081

docker run -e RPC_PORT --env-file .env -p 8081:8081 -v $PROJECT_DIR:/project -v /var/run/docker.sock:/var/run/docker.sock syncmaven/syncmaven:latest sync $SYNC_ARGS
