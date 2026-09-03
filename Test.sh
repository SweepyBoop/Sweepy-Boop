#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck source=ScriptHelpers.sh
source "${SCRIPT_DIR}/ScriptHelpers.sh"

usage() {
    printf 'Usage: %s [--off]\n' "$(basename -- "$0")"
    printf 'Enables test mode by default. Pass --off to disable it.\n'
}

TEST_VALUE="true"
case "${1:-}" in
    "")
        ;;
    --off|-Off)
        TEST_VALUE="false"
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

GAME_DIR="$(get_mac_wow_path)"
require_directory "${GAME_DIR}" "World of Warcraft installation"

CLIENTS=("_retail_" "_ptr_" "_classic_" "_classic_ptr_" "_anniversary_")
UPDATED=0

for client in "${CLIENTS[@]}"; do
    constants_file="${GAME_DIR}/${client}/Interface/AddOns/SweepyBoop/Common/Constants.lua"
    if [[ ! -f "${constants_file}" ]]; then
        printf 'Skipping missing installed addon: %s\n' "${constants_file}"
        continue
    fi

    replacement="addon.TEST_MODE = ${TEST_VALUE};"
    if grep -q 'addon\.TEST_MODE' "${constants_file}"; then
        REPLACEMENT="${replacement}" perl -0pi -e 's/addon\.TEST_MODE\s*=\s*.*?;/$ENV{REPLACEMENT}/g' "${constants_file}"
    else
        printf '\n%s\n' "${replacement}" >> "${constants_file}"
    fi

    printf 'Updated %s successfully.\n' "${constants_file}"
    UPDATED=$((UPDATED + 1))
done

if [[ "${UPDATED}" -eq 0 ]]; then
    printf 'No installed SweepyBoop copies were found under %s\n' "${GAME_DIR}" >&2
    exit 1
fi
