#!/usr/bin/env bash
set -euo pipefail

fetch_plugin() {
  local repository="$1" commit="$2" destination="$3"

  mkdir -p "${destination}"
  git -C "${destination}" init --quiet
  git -C "${destination}" remote add origin "https://github.com/${repository}.git"
  git -C "${destination}" fetch --quiet --depth=1 origin "${commit}"
  git -C "${destination}" checkout --quiet --detach FETCH_HEAD

  if [[ "$(git -C "${destination}" rev-parse HEAD)" != "${commit}" ]]; then
    printf 'Unexpected commit for %s\n' "${repository}" >&2
    exit 1
  fi
}

validate_plugin_paths() {
  local plugin_dir="$1" manifest="$2" component_path

  while IFS= read -r component_path; do
    if [[ ! -e "${plugin_dir}/${component_path}" ]]; then
      printf 'Missing plugin component: %s/%s\n' \
        "${plugin_dir}" "${component_path}" >&2
      exit 1
    fi
  done < <(jq -r '
    (.agents // [])[], (.skills // [])[],
    (.rules // [])[], (.extensions // [])[]
  ' "${manifest}")
}

main() {
  local -r squad_version="0.19.2"
  local -r squad_commit="66ba027c55b395cc026751606ae8dbc67c401c64"
  local -r core_commit="f60b057466bbdc79b78abcedfdda6b02f7740e3a"
  local -r marketplace_dir="/opt/hve/marketplace"
  local -r squad_dir="${marketplace_dir}/plugins/hve-squad"
  local -r core_dir="${marketplace_dir}/plugins/hve-squad-hve-core"
  local -r squad_manifest="${squad_dir}/.github/plugin/plugin.json"
  local -r core_manifest="${core_dir}/plugin.json"
  local -r upstream_marketplace="${squad_dir}/.github/plugin/marketplace.json"

  fetch_plugin "Peter-N91/hve-squad-plugin" "${squad_commit}" "${squad_dir}"
  fetch_plugin "microsoft/hve-core" "${core_commit}" "${core_dir}"

  jq --exit-status --arg version "${squad_version}" \
    '.name == "hve-squad" and .version == $version' \
    "${squad_manifest}" > /dev/null
  jq --exit-status --arg version "${squad_version}" --arg sha "${core_commit}" '
    .metadata.version == $version and
    any(.plugins[]; .name == "hve-squad" and .version == $version) and
    any(.plugins[]; .name == "hve-squad-hve-core" and .source.sha == $sha)
  ' "${upstream_marketplace}" > /dev/null

  validate_plugin_paths "${squad_dir}" "${squad_manifest}"
  validate_plugin_paths "${core_dir}" "${core_manifest}"
  [[ -f "${squad_dir}/hooks.json" && -f "${squad_dir}/.mcp.json" ]]

  mkdir -p "${marketplace_dir}/.github/plugin"
  jq '
    .plugins |= map(
      if .name == "hve-squad" then
        .source = "./plugins/hve-squad"
      elif .name == "hve-squad-hve-core" then
        .source = "./plugins/hve-squad-hve-core"
      else
        error("Unexpected plugin in the pinned marketplace")
      end
    )
  ' "${upstream_marketplace}" \
    > "${marketplace_dir}/.github/plugin/marketplace.json"

  jq --null-input --arg squad_version "${squad_version}" \
    --arg squad_commit "${squad_commit}" --arg core_commit "${core_commit}" \
    --arg core_version "$(jq -r '.version' "${core_manifest}")" '{
      apmVersion: "0.29.0",
      squadVersion: $squad_version,
      squadCommit: $squad_commit,
      hveCoreVersion: $core_version,
      hveCoreCommit: $core_commit
    }' > /opt/hve/versions.json
}

main "$@"