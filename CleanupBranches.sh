#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
FORCE=false

usage() {
    printf 'Usage: %s [--force]\n' "$(basename -- "$0")"
    printf 'Force-deletes every local Git branch except main after checking the worktree.\n'
}

case "${1:-}" in
    "")
        ;;
    --force|-f|-Force)
        FORCE=true
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

GIT_ROOT="$(git -C "${REPO_DIR}" rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'Not a Git repository: %s\n' "${REPO_DIR}" >&2
    exit 1
}
GIT_ROOT="$(CDPATH= cd -- "${GIT_ROOT}" && pwd -P)"
if [[ "${REPO_DIR}" != "${GIT_ROOT}" ]]; then
    printf 'Run this script from the repository root: %s\n' "${GIT_ROOT}" >&2
    exit 1
fi

CHANGES="$(git -C "${REPO_DIR}" status --porcelain=v1 --untracked-files=all | grep -Ev '^\?\? CleanupBranches\.(ps1|sh)$' || true)"
if [[ -n "${CHANGES}" ]]; then
    printf 'Uncommitted changes:\n%s\n' "${CHANGES}" >&2
    printf 'Commit or stash these changes before deleting branches.\n' >&2
    exit 1
fi

git -C "${REPO_DIR}" switch main
BRANCHES="$(git -C "${REPO_DIR}" for-each-ref --format='%(refname:short)' refs/heads | grep -v '^main$' || true)"
if [[ -z "${BRANCHES}" ]]; then
    printf 'No local branches to delete.\n'
    exit 0
fi

printf 'The following local branches will be force-deleted:\n%s\n' "$(printf '%s\n' "${BRANCHES}" | sed 's/^/  /')"
if [[ "${FORCE}" != true ]]; then
    printf 'Delete all local branches listed above? [y/N] '
    read -r confirmation
    case "${confirmation}" in
        y|Y|yes|YES|Yes)
            ;;
        *)
            printf 'Cancelled.\n'
            exit 0
            ;;
    esac
fi

COUNT=0
while IFS= read -r branch; do
    [[ -z "${branch}" ]] && continue
    git -C "${REPO_DIR}" branch -D -- "${branch}"
    COUNT=$((COUNT + 1))
done <<< "${BRANCHES}"

printf 'Deleted %d local branches. The current branch is main.\n' "${COUNT}"
