#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
PUBLISH_DIR="${SCRIPT_DIR}/SweepyBoop"
ARCHIVE_PATH="${SCRIPT_DIR}/SweepyBoop.zip"

should_exclude_directory() {
    case "$1" in
        .git*|.vscode|.VSCode|*Docs*|*Internal*|*VSCode*|Tools|wow-icon-upscale-workbench|SweepyBoop)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

rm -rf -- "${PUBLISH_DIR}"
rm -f -- "${ARCHIVE_PATH}"
mkdir -p -- "${PUBLISH_DIR}"

for extension in '*.lua' '*.toc' '*.xml'; do
    while IFS= read -r -d '' source_path; do
        cp -p -- "${source_path}" "${PUBLISH_DIR}/"
    done < <(find "${SCRIPT_DIR}" -maxdepth 1 -type f -name "${extension}" -print0)
done

while IFS= read -r -d '' directory; do
    if should_exclude_directory "$(basename -- "${directory}")"; then
        continue
    fi
    cp -R -- "${directory}" "${PUBLISH_DIR}/"
done < <(find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)

find "${PUBLISH_DIR}" -type f -name '.DS_Store' -delete

for excluded_name in Tools wow-icon-upscale-workbench Internal; do
    if [[ -e "${PUBLISH_DIR}/${excluded_name}" ]]; then
        printf 'Excluded directory entered the publication tree: %s\n' "${PUBLISH_DIR}/${excluded_name}" >&2
        exit 1
    fi
done

while IFS= read -r -d '' toc_file; do
    temporary_file="${toc_file}.new"
    grep -v 'Internal' "${toc_file}" > "${temporary_file}" || true
    mv -- "${temporary_file}" "${toc_file}"
done < <(find "${PUBLISH_DIR}" -maxdepth 1 -type f -name '*.toc' -print0)

if command -v ditto >/dev/null 2>&1; then
    ditto -c -k --norsrc --keepParent "${PUBLISH_DIR}" "${ARCHIVE_PATH}"
elif command -v zip >/dev/null 2>&1; then
    (
        cd "${SCRIPT_DIR}"
        COPYFILE_DISABLE=1 zip -q -r "${ARCHIVE_PATH}" SweepyBoop -x '*/.DS_Store' '*/__MACOSX/*'
    )
else
    printf 'Neither ditto nor zip is available to create %s\n' "${ARCHIVE_PATH}" >&2
    exit 1
fi

ARCHIVE_ENTRIES="$(unzip -Z1 "${ARCHIVE_PATH}")"
if ! awk 'index($0, "SweepyBoop/") != 1 { exit 1 }' <<< "${ARCHIVE_ENTRIES}"; then
    printf 'Archive contains an entry outside the SweepyBoop/ directory.\n' >&2
    exit 1
fi
if grep -Eq '(^|/)(__MACOSX|\.DS_Store)(/|$)' <<< "${ARCHIVE_ENTRIES}"; then
    printf 'Archive contains unwanted macOS metadata.\n' >&2
    exit 1
fi

printf 'Created publish-ready archive: %s\n' "${ARCHIVE_PATH}"
printf 'Every archive entry is under SweepyBoop/.\n'
