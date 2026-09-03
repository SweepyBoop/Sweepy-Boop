#!/usr/bin/env bash

SCRIPT_HELPERS_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
WOW_PATHS_FILE="${SCRIPT_HELPERS_DIR}/WoWInstallPaths.txt"

read_config_value() {
    local key="$1"
    local value

    if [[ ! -f "${WOW_PATHS_FILE}" ]]; then
        printf 'Configuration file is missing: %s\n' "${WOW_PATHS_FILE}" >&2
        return 1
    fi

    value="$(awk -v key="${key}" '
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        {
            separator = index($0, "=")
            if (separator == 0) { next }
            candidate = substr($0, 1, separator - 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
            if (candidate == key) {
                value = substr($0, separator + 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                print value
                exit
            }
        }
    ' "${WOW_PATHS_FILE}")"

    if [[ -z "${value}" ]]; then
        printf '%s is not set in %s\n' "${key}" "${WOW_PATHS_FILE}" >&2
        return 1
    fi

    printf '%s\n' "${value}"
}

get_mac_wow_path() {
    read_config_value "MAC_WOW_PATH"
}

require_directory() {
    local path="$1"
    local description="$2"

    if [[ ! -d "${path}" ]]; then
        printf '%s was not found: %s\n' "${description}" "${path}" >&2
        printf 'Update %s after the installation is available.\n' "${WOW_PATHS_FILE}" >&2
        return 1
    fi
}
