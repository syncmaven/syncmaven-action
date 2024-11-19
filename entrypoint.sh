#!/usr/bin/env bash

# Function to escape special characters - line breaks and quotes, so the value
# can be inlined in the command line
escape() {
  local input="$*"
  printf '%q' "$input"
}

# Gets env var value, supports names with '-' and '.' characters. Like VAR-XXX
getenv() {
  local var_name=$1
  local default_value=$2
  local value=$(printenv | grep $var_name)
  if [ -z "$value" ]; then
    echo $default_value
  else
    echo $value | cut -d'=' -f2
  fi
}

#unlike printenv, this function will print multi-line values correctly
print_env_vars() {
  local name
  for name in $(env | cut -d= -f1); do
    # Retrieve and print the value using eval
    local value=$(eval echo \$$name)
    echo "$name=$value"
  done
}

main() {
  # Save all environment variables to .env file
  awk 'BEGIN{for(v in ENVIRON) print v}' > .env

  SYNC_ARGS=()

  DEBUG_MODE=false
  if [ -n "$INPUT_DEBUG" ]; then
    SYNC_ARGS+=("--debug")
    echo "Input variables:"
    print_env_vars
    DEBUG_MODE=true
  fi

  REPOSITORY=$(basename "$RUNNER_WORKSPACE")


  PROJECT_DIR="$RUNNER_WORKSPACE/$REPOSITORY"

  if [ -n "$INPUT_DIR" ]; then
    PROJECT_DIR="$PROJECT_DIR/$INPUT_DIR"
  fi

  # Mapping of INPUT variables to command-line options
  declare -A ARG_MAPPING=(
    ["INPUT_SELECT"]="--select"
    ["INPUT_STATE"]="--state"
    ["INPUT_FULL"]="--full-refresh"
    ["INPUT_MODEL"]="--model"
    ["INPUT_DATASOURCE"]="--datasource"
    ["INPUT_CREDENTIALS"]="--credentials"
    ["INPUT_SYNC-ID"]="--sync-id"
    ["INPUT_PACKAGE"]="--package"
    ["INPUT_PACKAGE-TYPE"]="--package-type"

  )

  for VAR in "${!ARG_MAPPING[@]}"; do
    VALUE=$(getenv "$VAR")
    if [ -n "$VALUE" ]; then
      ARG="${ARG_MAPPING[$VAR]}"
      VALUE="$(escape "$VALUE")"
      # For flags without values (e.g., --full-refresh), don't add the value
      if [ "$ARG" == "--full-refresh" ]; then
        SYNC_ARGS+=("$ARG")
      else
        SYNC_ARGS+=("$ARG" "$VALUE")
      fi
    fi
  done

  SYNCMAVEN_VERSION=$(getenv "INPUT_SYNCMAVEN-VERSION" "latest")


  export RPC_PORT=8081

  # Build the docker command as an array
  DOCKER_CMD=(
    docker run
    -e RPC_PORT
    --env-file .env
    -p 8081:8081
    -v "$PROJECT_DIR:/project"
    -v /var/run/docker.sock:/var/run/docker.sock
    "syncmaven/syncmaven:${SYNCMAVEN_VERSION}"
    sync
    "${SYNC_ARGS[@]}"
  )

  if [ "$DEBUG_MODE" = true ]; then
    echo "Docker command:" "${DOCKER_CMD[@]}"
  fi

  # Execute the docker command
  "${DOCKER_CMD[@]}"
}

main "$@"