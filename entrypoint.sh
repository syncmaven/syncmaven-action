#!/usr/bin/env bash

awk 'BEGIN{for(v in ENVIRON) print v}' > .env

SYNC_ARGS=""

RETRY=0

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

if [ ! -z $INPUT_RETRY ]; then
  RETRY=$INPUT_RETRY
fi

export RPC_PORT=8081

STATUS=1

for i in $(seq 0 $RETRY); do
  if [ $i -gt 0 ]; then
    echo "\n\nRetrying sync attempt $i of $RETRY..."
  fi

  docker run -e RPC_PORT --env-file .env -p 8081:8081 -v $PROJECT_DIR:/project -v /var/run/docker.sock:/var/run/docker.sock syncmaven/syncmaven:latest sync $SYNC_ARGS
  STATUS=$?
  if [ $STATUS -eq 0 ]; then
    echo "Sync completed successfully."
    exit 0
  else
    echo "Sync failed with status $STATUS."
  fi
done

exit $STATUS
