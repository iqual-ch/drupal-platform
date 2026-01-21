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

APP_ROOT=${DDEV_COMPOSER_ROOT:-app}
COMPOSER_JSON_FILE="${APP_ROOT}/composer.json"

if [ ! -f "${COMPOSER_JSON_FILE}" ]; then
  echo "composer.json file not found. Aborting."
  exit 1
fi

if [[ -n "$RSH" && "$RSH" == "make-cli" ]]; then
  echo "Using remote shell: make cli"
fi

if [[ -n "$RSH" && "$RSH" == "ddev" ]]; then
  echo "Using remote shell: ddev"
fi

function rsh {
  echo "$@"
  if [[ -n "$RSH" && "$RSH" == "make-cli" ]]; then
    # Make sure the arguments' value is quoted in a format that can be reused as input.
    COMMAND="${*@Q}" make cli
  elif [[ -n "$RSH" && "$RSH" == "ddev" ]]; then
    ddev exec -- "${*@Q}"
  else
    eval "${*@Q}"
  fi
}

# Check if the the string is a key in the composer requirements.
function package_required {
  MATCH_VALUE=$1
  RESULT=$(jq -r ".require + .[\"require-dev\"] | select(.\"${MATCH_VALUE}\")" "${COMPOSER_JSON_FILE}")
  [ -n "${RESULT}" ]
}

# Check if the string is an installed package (composer.lock).
function package_installed {
  PACKAGE_VALUE=$1
  RESULT=$(jq -r ".packages[] | select(.name==\"${PACKAGE_VALUE}\")" "${COMPOSER_JSON_FILE/.json/.lock}")
  [ -n "${RESULT}" ]
}

# Check if the the string is a key in the composer requirements.
function name_matches {
  NAME_VALUE=$1
  RESULT=$(jq -r "select(.name==\"${NAME_VALUE}\") | .name" "${COMPOSER_JSON_FILE}")
  [ -n "${RESULT}" ]
}

# Check if the the string is an installed drupal extension.
function drupal_extension_installed {
  EXTENSION_VALUE=$1
  CORE_EXTENSION_FILE="$(find "${APP_ROOT}/" -maxdepth 8 -type f -name "core.extension.yml"| head -n 1)"
  if [ -n "${CORE_EXTENSION_FILE}" ]; then
    RESULT=$(grep -E "^\s*${EXTENSION_VALUE}:" "${CORE_EXTENSION_FILE}")
  fi
  [ -n "${RESULT}" ]
}

# Read operations into a bash array
readarray -t OPERATIONS < <(echo "${JSON_INPUT}" | jq -c '.operations[]')

# Run all the operations sequentially.
for operation in "${OPERATIONS[@]}"; do
  ACTION=$(echo "${operation}" | jq -r '.action')
  MATCH=$(echo "${operation}" | jq -r '.match // ""')
  MATCH_INVERSE=$(echo "${operation}" | jq -r '.matchInverse // ""')
  MATCH_LOCK=$(echo "${operation}" | jq -r '.matchLock // ""')
  MATCH_LOCK_INVERSE=$(echo "${operation}" | jq -r '.matchLockInverse // ""')
  MATCH_NAME=$(echo "${operation}" | jq -r '.matchName // ""')
  MATCH_NAME_INVERSE=$(echo "${operation}" | jq -r '.matchNameInverse // ""')
  MATCH_EXTENSION=$(echo "${operation}" | jq -r '.matchExtension // ""')
  MATCH_EXTENSION_INVERSE=$(echo "${operation}" | jq -r '.matchExtensionInverse // ""')

  echo -e "---------------------------------------------------"
  echo -e "\tRunning action: ${ACTION}"
  echo -e "---------------------------------------------------"

  # Check if operation matches composer requirements.
  if [ -n "${MATCH}" ] && ! package_required "${MATCH}"; then
    echo "Didn't match \"${MATCH}\" in composer.json. Skipping operation."
    continue
  fi

  # Check if operation doesn't match composer requirements.
  if [ -n "${MATCH_INVERSE}" ] && package_required "${MATCH_INVERSE}"; then
    echo "Matched \"${MATCH_INVERSE}\" in composer.json. Skipping operation."
    continue
  fi

  # Check if operation matches composer requirements.
  if [ -n "${MATCH_LOCK}" ] && ! package_installed "${MATCH_LOCK}"; then
    echo "Didn't match \"${MATCH_LOCK}\" in composer.lock. Skipping operation."
    continue
  fi

  # Check if operation doesn't match composer requirements.
  if [ -n "${MATCH_LOCK_INVERSE}" ] && package_installed "${MATCH_LOCK_INVERSE}"; then
    echo "Matched \"${MATCH_LOCK_INVERSE}\" in composer.lock. Skipping operation."
    continue
  fi

  # Check if operation matches composer project name.
  if [ -n "${MATCH_NAME}" ] && ! name_matches "${MATCH_NAME}"; then
    echo "Didn't match \"${MATCH_NAME}\" name in composer.json. Skipping operation."
    continue
  fi

  # Check if operation doesn't match composer project name.
  if [ -n "${MATCH_NAME_INVERSE}" ] && name_matches "${MATCH_NAME_INVERSE}"; then
    echo "Matched \"${MATCH_NAME_INVERSE}\" name in composer.json. Skipping operation."
    continue
  fi

  # Check if operation matches installed drupal extensions.
  if [ -n "${MATCH_EXTENSION}" ] && ! drupal_extension_installed "${MATCH_EXTENSION}"; then
    echo "Didn't match \"${MATCH_EXTENSION}\" in core.extension.yml. Skipping operation."
    continue
  fi

  # Check if operation doesn't match installed drupal extensions.
  if [ -n "${MATCH_EXTENSION_INVERSE}" ] && drupal_extension_installed "${MATCH_EXTENSION_INVERSE}"; then
    echo "Matched \"${MATCH_EXTENSION_INVERSE}\" in core.extension.yml. Skipping operation."
    continue
  fi

  # Parse OPTIONS into an array to preserve arguments with spaces
  OPTIONS_STRING=$(echo "${operation}" | jq -r '.options // ""')
  if [[ -n "${OPTIONS_STRING}" ]]; then
    read -ra OPTIONS_ARRAY <<< "$OPTIONS_STRING"
  else
    OPTIONS_ARRAY=()
  fi

  # Parse DATA into an array to preserve each item separately (handles spaces in items)
  DATA_INPUT=$(echo "${operation}" | jq '.data')
  if [[ -n "${DATA_INPUT}" ]] && [[ "${DATA_INPUT}" != "null" ]]; then
    if echo "${DATA_INPUT}" | jq -e 'type=="array"' > /dev/null; then
      # Convert JSON array to bash array, one element per line
      readarray -t DATA_ARRAY < <(echo "${DATA_INPUT}" | jq -r '.[]')
    else
      # Single value - convert to single-element array
      DATA_ARRAY=("$(echo "${DATA_INPUT}" | jq -r '.')")
    fi
  else
    DATA_ARRAY=()
  fi

  KEY=$(echo "${operation}" | jq -r '.key')

  # Switch to relevant action.
  case "${ACTION}" in
    "remove")
      rsh composer remove "${OPTIONS_ARRAY[@]}" -n "${DATA_ARRAY[@]}" -d "${APP_ROOT}"
      ;;
    "require")
      rsh composer require "${OPTIONS_ARRAY[@]}" -n "${DATA_ARRAY[@]}" -d "${APP_ROOT}"
      ;;
    "update")
      rsh composer update "${OPTIONS_ARRAY[@]}" -n "${DATA_ARRAY[@]}" -d "${APP_ROOT}"
      ;;
    "bump")
      rsh composer bump "${OPTIONS_ARRAY[@]}" "${DATA_ARRAY[@]}" -n -d "${APP_ROOT}"
      ;;
    "config")
      if [[ "${KEY}" =~ "extra."* ]] || [[ "${KEY}" =~ "repositories."* ]]; then
        # For complex configs, use JSON format to preserve structure
        DATA_JSON=$(echo "${operation}" | jq -c '.data')
        rsh composer config "${KEY}" "${OPTIONS_ARRAY[@]}" --json "${DATA_JSON}" -n -d "${APP_ROOT}"
      else
        # For simple configs, pass data array elements
        rsh composer config "${KEY}" "${DATA_ARRAY[@]}" "${OPTIONS_ARRAY[@]}" -n -d "${APP_ROOT}"
      fi
      ;;
    "rector")
      if ! grep -q "palantirnet/drupal-rector" "$COMPOSER_JSON_FILE"; then
        echo "Rector is not present, installing it temporarily."
        rsh composer require --dev palantirnet/drupal-rector -n -d "${APP_ROOT}"
        RECTOR_INSTALLED=true
      fi
      RECTOR_CONFIG="${APP_ROOT}/rector.php"
      if [ ! -f "${RECTOR_CONFIG}" ]; then
        echo "Rector configuration is not present, using default."
        RECTOR_CONFIG=".github/actions/upgrade/rector.php"
      fi
      if [[ ${#DATA_ARRAY[@]} -eq 0 ]]; then
        echo "No path defined. Auto-generating themes and module custom path."
        # Build array from auto-generated paths
        readarray -t DATA_ARRAY < <(git ls-tree -d -r $(git write-tree) --name-only | grep -E '(themes|modules)/custom/[^/]+$')
      fi
      rsh rector process "${DATA_ARRAY[@]}" "${OPTIONS_ARRAY[@]}" --config "${RECTOR_CONFIG}"
      if [ -n "$RECTOR_INSTALLED" ]; then
        rsh composer remove --dev palantirnet/drupal-rector -n -d "${APP_ROOT}"
      fi
      ;;
    "phpcbf")
      if grep -q "drupal/coder" "$COMPOSER_JSON_FILE"; then
        if [[ ${#DATA_ARRAY[@]} -eq 0 ]]; then
          echo "No path defined. Auto-generating themes and module custom path."
          # Build array from auto-generated paths
          readarray -t DATA_ARRAY < <(git ls-tree -d -r $(git write-tree) --name-only | grep -E '(themes|modules)/custom/[^/]+$')
        fi
        rsh phpcbf "${OPTIONS_ARRAY[@]}" "${DATA_ARRAY[@]}" || true
      else
        echo "Warning: missing \"drupal/coder\" package for code beautifying"
      fi
      ;;
    "updatedb")
      rsh drush updatedb "${OPTIONS_ARRAY[@]}" -y
      ;;
    "cache:rebuild")
      rsh drush cache:rebuild
      ;;
    "pm:enable")
      rsh drush pm:enable "${OPTIONS_ARRAY[@]}" -y "${DATA_ARRAY[@]}"
      ;;
    "pm:uninstall")
      rsh drush pm:uninstall "${OPTIONS_ARRAY[@]}" -y "${DATA_ARRAY[@]}"
      ;;
    "theme:enable")
      rsh drush theme:enable "${OPTIONS_ARRAY[@]}" -y "${DATA_ARRAY[@]}"
      ;;
    "theme:uninstall")
      rsh drush theme:uninstall "${OPTIONS_ARRAY[@]}" -y "${DATA_ARRAY[@]}"
      ;;
    "config:export")
      rsh drush config:export -y "${OPTIONS_ARRAY[@]}"
      ;;
    "config:set")
      # Requires at least drush v11
      # Use JSON format to preserve complex data structures
      DATA_JSON=$(echo "${operation}" | jq -c '.data')
      rsh drush config:set -y "${OPTIONS_ARRAY[@]}" --input-format=yaml "${KEY}" ? "${DATA_JSON}"
      ;;
    "project:scaffold")
      rsh composer project:scaffold -n "${OPTIONS_ARRAY[@]}" -d "${APP_ROOT}"
      ;;
    "drupal:scaffold")
      rsh composer drupal:scaffold -n "${OPTIONS_ARRAY[@]}" -d "${APP_ROOT}"
      ;;
    "patch-add")
      if grep -q "szeidler/composer-patches-cli" "$COMPOSER_JSON_FILE"; then
        # DATA_ARRAY is already properly populated from JSON parsing above
        rsh composer patch-add "${OPTIONS_ARRAY[@]}" -n "${DATA_ARRAY[@]}" -d "${APP_ROOT}"
      else
        echo "Warning: missing \"szeidler/composer-patches-cli\" package for patch CLI."
      fi
      ;;
    "patch-remove")
      if grep -q "szeidler/composer-patches-cli" "$COMPOSER_JSON_FILE"; then
        # DATA_ARRAY is already properly populated from JSON parsing above
        rsh composer patch-remove "${OPTIONS_ARRAY[@]}" -n "${DATA_ARRAY[@]}" -d "${APP_ROOT}"
      else
        echo "Warning: missing \"szeidler/composer-patches-cli\" package for patch CLI."
      fi
      ;;
    "commit")
      # For commit, DATA contains the commit message which should be a single string
      # Join DATA_ARRAY if it has multiple elements (shouldn't normally happen)
      COMMIT_MSG="${DATA_ARRAY[*]}"
      echo "git add . && git commit ${OPTIONS_ARRAY[@]} -m \"${COMMIT_MSG}\" || true"
      git add . && git commit "${OPTIONS_ARRAY[@]}" -m "${COMMIT_MSG}" || true
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
