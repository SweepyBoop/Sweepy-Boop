#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck source=scriptHelpers.sh
source "${SCRIPT_DIR}/scriptHelpers.sh"

GAME_DIR="$(get_mac_wow_path)"
require_directory "${GAME_DIR}" "World of Warcraft installation"

BIG_DEBUFFS_DIR="${GAME_DIR}/_retail_/Interface/AddOns/BigDebuffs"
require_directory "${BIG_DEBUFFS_DIR}" "BigDebuffs addon"

build_aura_file() {
    local input_file="$1"
    local output_file="$2"
    local temporary_file

    if [[ ! -f "${input_file}" ]]; then
        printf 'BigDebuffs source file was not found: %s\n' "${input_file}" >&2
        return 1
    fi

    temporary_file="$(mktemp "${TMPDIR:-/tmp}/sweepyboop-auras.XXXXXX")"
    trap 'rm -f -- "${temporary_file}"' RETURN

    awk '
        /type = CROWD_CONTROL/ || /type = ROOT/ {
            if ($0 !~ /\[[0-9]+\].*--[[:space:]]*.+$/) {
                next
            }
            id = $0
            sub(/^[^[]*\[/, "", id)
            sub(/\].*$/, "", id)
            comment = $0
            sub(/^.*--[[:space:]]*/, "", comment)
            comments[id] = comment
        }
        END {
            for (id in comments) {
                printf "%d\t%s\n", id, comments[id]
            }
        }
    ' "${input_file}" | sort -n > "${temporary_file}"

    {
        printf 'local _, addon = ...;\n\n'
        printf 'addon.CrowdControlAuras = {\n'
        awk -F '\t' '{ printf "    [%s] = true, -- %s\n", $1, $2 }' "${temporary_file}"
        printf '};\n'
    } > "${output_file}"

    rm -f -- "${temporary_file}"
    trap - RETURN
    printf 'Crowd control IDs with comments were written to %s successfully.\n' "${output_file}"
}

build_aura_file \
    "${BIG_DEBUFFS_DIR}/BigDebuffs_Mainline.lua" \
    "${SCRIPT_DIR}/Common/CrowdControlAuras.lua"
build_aura_file \
    "${BIG_DEBUFFS_DIR}/BigDebuffs_Cata.lua" \
    "${SCRIPT_DIR}/Common/CrowdControlAuras_Cata.lua"
