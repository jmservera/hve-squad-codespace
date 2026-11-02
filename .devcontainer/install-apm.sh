#!/usr/bin/env bash
set -euo pipefail

main() {
  local -r apm_version="0.29.0"
  local -r install_dir="/usr/local/lib/apm"
  local architecture checksum version_output

  case "$(uname -m)" in
    x86_64)
      architecture="x86_64"
      checksum="53c98c50f436a8b5ac1d6a3cf443f94d29ed1e5385af52859cf1b1b512f71578"
      ;;
    aarch64|arm64)
      architecture="arm64"
      checksum="84592865853f0c13d34a1f5021463a55deb5d1245061dd31a69f3ec61972d21f"
      ;;
    *)
      printf 'Unsupported APM architecture: %s\n' "$(uname -m)" >&2
      exit 1
      ;;
  esac

  temporary_dir="$(mktemp -d /tmp/apm.XXXXXXXX)"
  trap 'rm -rf -- "${temporary_dir}"' EXIT

  curl --fail --silent --show-error --location --retry 3 \
    "https://github.com/microsoft/apm/releases/download/v${apm_version}/apm-linux-${architecture}.tar.gz" \
    --output "${temporary_dir}/apm.tar.gz"
  printf '%s  %s\n' "${checksum}" "${temporary_dir}/apm.tar.gz" \
    | sha256sum --check --strict

  mkdir -p "${install_dir}"
  tar --extract --gzip --no-same-owner --strip-components=1 \
    --file "${temporary_dir}/apm.tar.gz" --directory "${install_dir}"
  chmod 0755 "${install_dir}/apm"

  version_output="$("${install_dir}/apm" --version)"
  if [[ ! "${version_output}" =~ (^|[^0-9.])0\.29\.0([^0-9.]|$) ]]; then
    printf 'Expected APM %s; got %s\n' \
      "${apm_version}" "${version_output}" >&2
    exit 1
  fi

  ln -sf "${install_dir}/apm" /usr/local/bin/apm
  printf '%s\n' "${version_output}"
}

main "$@"