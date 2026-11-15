#!/usr/bin/env bash
set -euo pipefail

docker_args=()
case "${1:-}" in
  login) docker_args=(-it); args=(login --device-auth) ;;
  status) args=(login status) ;;
  test) args=(-a never exec --ephemeral --sandbox danger-full-access
    --skip-git-repo-check "Antworte nur mit FACTORY_OK.") ;;
  *) echo "Aufruf: sudo bash scripts/codex-auth.sh {login|status|test}" >&2; exit 2 ;;
esac

exec docker run --rm "${docker_args[@]}" --cap-drop=ALL --security-opt=no-new-privileges \
  --mount type=bind,source=/etc/software-factory/codex-auth,target=/codex-auth \
  -e CODEX_HOME=/codex-auth --entrypoint factory-codex software-factory-job:latest "${args[@]}"
