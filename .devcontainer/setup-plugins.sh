#!/usr/bin/env bash
set -euo pipefail

main() {
  local marketplaces_json
  marketplaces_json="$(copilot plugin marketplace list --json)"
  if ! jq --exit-status '
    any(.[];
      .name == "hve-squad-plugin" and .source == "Local: /opt/hve/marketplace"
    )
  ' <<< "${marketplaces_json}" > /dev/null; then
    copilot plugin marketplace add /opt/hve/marketplace
  fi
  copilot plugin install hve-squad@hve-squad-plugin
  copilot plugin enable hve-squad-hve-core@hve-squad-plugin
  bash /usr/local/share/hve/verify.sh
}

main "$@"