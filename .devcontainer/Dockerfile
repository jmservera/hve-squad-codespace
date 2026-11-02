FROM mcr.microsoft.com/devcontainers/base:1-ubuntu-24.04

COPY .devcontainer/install-apm.sh /tmp/install-apm.sh
RUN bash /tmp/install-apm.sh && rm /tmp/install-apm.sh

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates curl git jq \
	&& rm -rf /var/lib/apt/lists/*

COPY .devcontainer/prepare-plugins.sh .devcontainer/setup-plugins.sh .devcontainer/verify.sh /usr/local/share/hve/
RUN bash /usr/local/share/hve/prepare-plugins.sh \
	&& chmod 0755 /usr/local/share/hve/*.sh

ARG SOURCE_REPOSITORY=jmservera/hve-squad-codespace
LABEL org.opencontainers.image.source="https://github.com/${SOURCE_REPOSITORY}"

USER vscode