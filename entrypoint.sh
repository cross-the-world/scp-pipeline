#!/bin/bash

set -e

createKeyFile() {
  local SSH_PATH="$HOME/.ssh"

  mkdir -p "$SSH_PATH"
  touch "$SSH_PATH/known_hosts"

  echo "$INPUT_KEY" > "$SSH_PATH/id_rsa"

  chmod 700 "$SSH_PATH"
  chmod 600 "$SSH_PATH/known_hosts"
  chmod 600 "$SSH_PATH/id_rsa"

  eval $(ssh-agent)
  ssh-add "$SSH_PATH/id_rsa"

  ssh-keyscan -t rsa "$INPUT_HOST" >> "$SSH_PATH/known_hosts"
}

check_remote_dir() {
  local USEPASS=$1
  local REMOTE=$2
  local CMD="ssh"
  if $USEPASS; then
    CMD="sshpass -p $INPUT_PASS ssh"
  fi
  echo "Checking remote directory: '$REMOTE'"
  if $CMD -o StrictHostKeyChecking=no -o ConnectTimeout=${INPUT_CONNECT_TIMEOUT:-30s} -p "${INPUT_PORT:-22}" "$INPUT_USER"@"$INPUT_HOST" "[ ! -d $REMOTE ]"; then
    echo "Creating: '$REMOTE' on '$INPUT_USER'@'$INPUT_HOST'"
    $CMD -o StrictHostKeyChecking=no -o ConnectTimeout=${INPUT_CONNECT_TIMEOUT:-30s} -p "${INPUT_PORT:-22}" "$INPUT_USER"@"$INPUT_HOST" "mkdir -p $REMOTE"
  else
    echo "'$REMOTE' exists [OK]"
  fi
}

executeSCP() {
  local USEPASS=$1
  local LINES=$2
  local COMMAND=

  local CMD="scp"
  if $USEPASS; then
    CMD="sshpass -p $INPUT_PASS scp"
  fi

  while IFS= read -r LINE; do
    delimiter="=>"
    LINE=$(echo $LINE)
    if [[ -z "${LINE}" ]]; then
      continue
    fi
    s=$LINE$delimiter
    arr=()
    while [[ $s ]]; do
        arr+=( "${s%%"$delimiter"*}" );
        s=${s#*"$delimiter"};
    done;
    LOCAL=$(eval 'echo "${arr[0]}"')
    LOCAL=$(eval echo "$LOCAL")
    REMOTE=$(eval 'echo "${arr[1]}"')
    REMOTE=$(eval echo "$REMOTE")

    if [[ -z "${LOCAL}" ]] || [[ -z "${REMOTE}" ]]; then
      echo "LOCAL/REMOTE can not be parsed $LINE"
    else
      check_remote_dir $USEPASS $REMOTE
      echo "Copying $LOCAL ---> $REMOTE"
      $CMD -r -o StrictHostKeyChecking=no -o ConnectTimeout=${INPUT_CONNECT_TIMEOUT:-30s} -P "${INPUT_PORT:-22}" $LOCAL "$INPUT_USER"@"$INPUT_HOST":$REMOTE > /dev/stdout
    fi
  done <<< "$LINES"
}


######################################################################################

echo "+++++++++++++++++++STARTING PIPELINES+++++++++++++++++++"

USEPASS=true
if [[ -z "${INPUT_KEY}" ]]; then
  echo "+++++++++++++++++++Use password+++++++++++++++++++"
else
  echo "+++++++++++++++++++Create Key File+++++++++++++++++++"
  USEPASS=false
  createKeyFile || false
fi

if ! [[ -z "${INPUT_LOCAL}" ]] && ! [[ -z "${INPUT_REMOTE}" ]]; then
  echo "+++++++++++++++++++Pipeline: LOCAL -> REMOTE+++++++++++++++++++"
  executeSCP "$USEPASS" "$INPUT_LOCAL => $INPUT_REMOTE" || false
fi

if ! [[ -z "${INPUT_SCP}" ]]; then
  echo "+++++++++++++++++++Pipeline: RUNNING SCP+++++++++++++++++++"
  executeSCP "$USEPASS" "$INPUT_SCP" || false
fi

echo "+++++++++++++++++++END PIPELINES+++++++++++++++++++"
