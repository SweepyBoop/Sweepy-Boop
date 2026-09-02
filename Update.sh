#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck source=ScriptHelpers.sh
source "${SCRIPT_DIR}/ScriptHelpers.sh"

GAME_DIR="$(get_mac_wow_path)"
require_directory "${GAME_DIR}" "World of Warcraft installation"

EXTENSIONS=("*.lua" "*.toc" "*.xml")
CLIENTS=("_retail_" "_ptr_" "_classic_" "_classic_ptr_" "_anniversary_")
DEPLOYED=0

should_exclude_directory() {
    case "$1" in
        .git*|*Docs*|Tools|wow-icon-upscale-workbench|SweepyBoop)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

deploy_addon() {
    local source_dir="$1"
    local destination_dir="$2"
    local extension
    local source_path
    local directory

    rm -rf -- "${destination_dir}"
    mkdir -p -- "${destination_dir}"

    for extension in "${EXTENSIONS[@]}"; do
        while IFS= read -r -d '' source_path; do
            cp -p -- "${source_path}" "${destination_dir}/"
        done < <(find "${source_dir}" -maxdepth 1 -type f -name "${extension}" -print0)
    done

    while IFS= read -r -d '' directory; do
        if should_exclude_directory "$(basename -- "${directory}")"; then
            continue
        fi
        cp -R -- "${directory}" "${destination_dir}/"
    done < <(find "${source_dir}" -mindepth 1 -maxdepth 1 -type d -print0)

    if [[ ! -f "${destination_dir}/Common/Constants.lua" ]]; then
        printf 'Expected Constants.lua was not copied to %s\n' "${destination_dir}" >&2
        return 1
    fi
    printf '\naddon.internal = true;\n' >> "${destination_dir}/Common/Constants.lua"
    printf 'Deployed addon to %s\n' "${destination_dir}"
}

for client in "${CLIENTS[@]}"; do
    client_dir="${GAME_DIR}/${client}"
    if [[ ! -d "${client_dir}" ]]; then
        printf 'Skipping client that is not installed: %s\n' "${client_dir}"
        continue
    fi

    deploy_addon "${SCRIPT_DIR}" "${client_dir}/Interface/AddOns/SweepyBoop"
    DEPLOYED=$((DEPLOYED + 1))
done

if [[ "${DEPLOYED}" -eq 0 ]]; then
    printf 'No supported WoW client directories were found under %s\n' "${GAME_DIR}" >&2
    exit 1
fi
