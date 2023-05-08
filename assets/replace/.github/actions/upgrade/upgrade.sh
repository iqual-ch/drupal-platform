#!/bin/bash

# Drupal Upgrade script
#
# Requires a composer file in the APP_ROOT (default: ./app)
# Also requires a JSON_INPUT as either env var, stdin or file
#
# Usage:
#       ./upgrade.sh operation.json
# Alt:
#       cat operations.json | ./upgrade.sh
#       echo '{"operations":[{"action":"config:export"}]}' | ./upgrade.sh

set -eo pipefail

JSON_INPUT=${JSON_INPUT}

# Accept STDIN for pipe input.
if [[ -p /dev/stdin && ! -t 0 ]]; then
  JSON_STDIN=$(</dev/stdin)
  if [[ -n "$JSON_STDIN" ]]; then
    JSON_INPUT=${JSON_STDIN}
  fi
else
  # Accept file as an argument.
  if [[ -n "$1" && -f "$1" ]]; then
    JSON_INPUT=$(<"$1")
  fi
fi

if [[ -z "$JSON_INPUT" ]]; then
  echo "No input given!"
  echo "Usage: ./upgrade.sh operation.json"
  echo "Or by piping: cat operations.json | ./upgrade.sh"
  exit 1
fi

# Validate JSON input.
if ! jq -e . >/dev/null 2>&1 <<<"$JSON_INPUT"; then
  echo "Failed to parse JSON_INPUT. Aborting."
  jq -e . >/dev/null <<<"$JSON_INPUT"
  exit 1
fi

APP_ROOT=${APP_ROOT:-app}
COMPOSER_JSON_FILE="${APP_ROOT}/composer.json"

if [ ! -f "${COMPOSER_JSON_FILE}" ]; then
  echo "composer.json file not found. Aborting."
  exit 1
fi

if [[ -n "$RSH" && "$RSH" == "make-cli" ]]; then
  echo "Using remote shell: make cli"
fi

function rsh {
  echo "$@"
  if [[ -n "$RSH" && "$RSH" == "make-cli" ]]; then
    # Make sure the arguments' value is quoted in a format that can be reused as input.
    COMMAND="${*@Q}" make cli
  else
    eval "${*@Q}"
  fi
}

# Check if the the string is a key in the composer requirements.
function match_exists {
  MATCH_VALUE=$1
  RESULT=$(jq -r ".require + .[\"require-dev\"] | select(.\"${MATCH_VALUE}\")" "${COMPOSER_JSON_FILE}")
  [ -n "${RESULT}" ]
}

# Read operations into a bash array
readarray -t OPERATIONS < <(echo "${JSON_INPUT}" | jq -c '.operations[]')

# Run all the operations sequentially.
for operation in "${OPERATIONS[@]}"; do
  ACTION=$(echo "${operation}" | jq -r '.action')
  MATCH=$(echo "${operation}" | jq -r '.match // ""')
  MATCH_INVERSE=$(echo "${operation}" | jq -r '.matchInverse // ""')

  echo -e "---------------------------------------------------"
  echo -e "\tRunning action: ${ACTION}"
  echo -e "---------------------------------------------------"

  # Check if operation matches composer requirements.
  if [ -n "${MATCH}" ] && ! match_exists "${MATCH}"; then
    echo "Didn't match \"${MATCH}\". Skipping operation."
    continue
  fi

  # Check if operation doesn't match composer requirements.
  if [ -n "${MATCH_INVERSE}" ] && match_exists "${MATCH_INVERSE}"; then
    echo "Matched \"${MATCH_INVERSE}\". Skipping operation."
    continue
  fi

  OPTIONS=$(echo "${operation}" | jq -r '.options // ""')

  # Parse data variable and convert arrays into whitespace separated list.
  DATA_INPUT=$(echo "${operation}" | jq '.data')
  if [[ -n "${DATA_INPUT}" ]] && [[ "${DATA_INPUT}" != "null" ]]; then
    if echo "${DATA_INPUT}" | jq -e 'type=="array"' > /dev/null; then
        DATA=$(echo "${DATA_INPUT}" | jq -r 'join(" ")')
    else
        DATA=$(echo "${DATA_INPUT}" | jq -r '.')
    fi
  else
    DATA=
  fi

  KEY=$(echo "${operation}" | jq -r '.key')

  # Switch to relevant action.
  case "${ACTION}" in
    "remove")
      rsh composer remove ${OPTIONS} -n ${DATA} -d ${APP_ROOT}
      ;;
    "require")
      rsh composer require ${OPTIONS} -n ${DATA} -d ${APP_ROOT}
      ;;
    "update")
      rsh composer update ${OPTIONS} -n ${DATA} -d ${APP_ROOT}
      ;;
    "bump")
      rsh composer bump ${PACKAGES} -n -d ${APP_ROOT}
      ;;
    "config")
      if [[ "${KEY}" =~ "extra."* ]] || [[ "${KEY}" =~ "repositories."* ]]; then
        DATA_JSON=$(echo "${operation}" | jq -c '.data')
        rsh composer config ${KEY} ${OPTIONS} --json "${DATA_JSON}" -n -d ${APP_ROOT}
      else
        rsh composer config ${KEY} ${DATA} ${OPTIONS} -n -d ${APP_ROOT}
      fi
      ;;
    "rector")
      if ! grep -q "palantirnet/drupal-rector" $COMPOSER_JSON_FILE; then
        echo "Rector is not present, installing it temporarily."
        rsh composer require --dev palantirnet/drupal-rector -n -d ${APP_ROOT}
        RECTOR_INSTALLED=true
      fi
      RECTOR_CONFIG="${APP_ROOT}/rector.php"
      if [ ! -f "${RECTOR_CONFIG}" ]; then
        echo "Rector configuration is not present, using default."
        RECTOR_CONFIG=".github/actions/upgrade/rector.php"
      fi
      if [ -z "$DATA" ]; then
        echo "No path defined. Auto-generating themes and module custom path."
        DATA="$(git ls-tree -d -r $(git write-tree) --name-only | grep -E '(themes|modules)/custom/[^/]+$' | paste -s -d, -)"
      fi
      rsh rector process ${DATA} ${OPTIONS} --config ${RECTOR_CONFIG}
      if [ -n "$RECTOR_INSTALLED" ]; then
        rsh composer remove --dev palantirnet/drupal-rector -n -d ${APP_ROOT}
      fi
      ;;
    "phpcbf")
      if grep -q "drupal/coder" $COMPOSER_JSON_FILE; then
        if [ -z "$DATA" ]; then
          echo "No path defined. Auto-generating themes and module custom path."
          DATA="$(git ls-tree -d -r $(git write-tree) --name-only | grep -E '(themes|modules)/custom/[^/]+$' | paste -s -d, -)"
        fi
        rsh phpcbf ${OPTIONS} ${DATA} || true
      else
        echo "Warning: missing \"drupal/coder\" package for code beautifying"
      fi
      ;;
    "updatedb")
      rsh drush updatedb ${OPTIONS} -y
      ;;
    "pm:enable")
      rsh drush pm:enable ${OPTIONS} -y ${DATA}
      ;;
    "pm:uninstall")
      rsh drush pm:uninstall ${OPTIONS} -y ${DATA}
      ;;
    "theme:enable")
      rsh drush theme:enable ${OPTIONS} -y ${DATA}
      ;;
    "theme:uninstall")
      rsh drush theme:uninstall ${OPTIONS} -y ${DATA}
      ;;
    "config:export")
      rsh drush config:export -y ${OPTIONS}
      ;;
    "config:set")
      # Requires at least drush v11
      DATA_JSON=$(echo "${operation}" | jq -c '.data')
      rsh drush config:set -y ${OPTIONS} --input-format=yaml "${KEY}" ? "${DATA_JSON}"
      ;;
    "project:scaffold")
      rsh composer project:scaffold -n ${OPTIONS} -d ${APP_ROOT}
      ;;
    "drupal:scaffold")
      rsh composer drupal:scaffold -n ${OPTIONS} -d ${APP_ROOT}
      ;;
    "patch-add")
      if grep -q "szeidler/composer-patches-cli" $COMPOSER_JSON_FILE; then
        rsh composer patch-add ${OPTIONS} -n ${DATA} -d ${APP_ROOT}
      else
        echo "Warning: missing \"szeidler/composer-patches-cli\" package for patch CLI."
      fi
      ;;
    "patch-remove")
      if grep -q "szeidler/composer-patches-cli" $COMPOSER_JSON_FILE; then
        rsh composer patch-remove ${OPTIONS} -n ${DATA} -d ${APP_ROOT}
      else
        echo "Warning: missing \"szeidler/composer-patches-cli\" package for patch CLI."
      fi
      ;;
    "commit")
      echo "git add . && git commit ${OPTIONS} -m "${DATA}" || true"
      git add . && git commit ${OPTIONS} -m "${DATA}" || true
      ;;
    "reboot")
      echo "make deploy-local COMPOSE_FLAGS=-d"
      make deploy-local COMPOSE_FLAGS=-d
      ;;
    *)
      echo "Unsupported action: ${ACTION}"
      ;;
  esac

done

echo "Successfully finished upgrade operations."