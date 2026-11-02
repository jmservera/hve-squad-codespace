#!/usr/bin/env bash
set -euo pipefail

main() {
  local tool apm_version node_version dotnet_version plugins_json core_version

  for tool in apm copilot python3 node npm dotnet pwsh jq git gh; do
    command -v "${tool}" > /dev/null
  done

  apm_version="$(apm --version)"
  if [[ ! "${apm_version}" =~ (^|[^0-9.])0\.29\.0([^0-9.]|$) ]]; then
    printf 'APM must be 0.29.0; got %s\n' "${apm_version}" >&2
    exit 1
  fi
  printf '%s\n' "${apm_version}"
  copilot --version
  python3 --version
  node_version="$(node --version)"
  if [[ ! "${node_version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'A stable Node.js release is required; got %s\n' \
      "${node_version}" >&2
    exit 1
  fi
  printf '%s\n' "${node_version}"
  npm --version

  dotnet_version="$(dotnet --version)"
  [[ "${dotnet_version}" == 10.0.* ]]
  printf '.NET SDK %s\n' "${dotnet_version}"
  pwsh -NoLogo -NoProfile -Command \
    "if (\$PSVersionTable.PSVersion -lt [version]'7.4') { throw 'PowerShell 7.4+ is required' }; \$PSVersionTable.PSVersion.ToString()"

  jq --exit-status '
    .apmVersion == "0.29.0" and .squadVersion == "0.19.2"
  ' /opt/hve/versions.json > /dev/null
  core_version="$(jq -r '.hveCoreVersion' /opt/hve/versions.json)"
  plugins_json="$(copilot plugin list --json)"
  jq --exit-status --arg core_version "${core_version}" '
    any(.[];
      .name == "hve-squad" and .marketplace == "hve-squad-plugin" and
      .version == "0.19.2" and .enabled == true
    ) and
    any(.[];
      .name == "hve-squad-hve-core" and
      .marketplace == "hve-squad-plugin" and
      .version == $core_version and .enabled == true
    )
  ' <<< "${plugins_json}" > /dev/null

  printf '\nWorkshop tools and both pinned plugins are ready.\n'
  copilot plugin list
}

main "$@"