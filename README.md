---
title: HVE Workshop Dev Container
description: A shareable devcontainer for HVE Core and HVE Squad workshops with pinned agent tooling and common language runtimes.
---

## Workshop Environment

Open this repository in GitHub Codespaces or VS Code Dev Containers to get
HVE Squad and its matching HVE Core plugin, without deploying agent files into
your project or running `apm install`.

[Open in GitHub Codespaces](https://codespaces.new/jmservera/hve-squad-codespace)

| Component   | Version                                            |
| ----------- | -------------------------------------------------- |
| Base image  | Official Dev Containers Ubuntu 24.04               |
| APM CLI     | **0.29.0**, checksum-verified release bundle       |
| HVE Squad   | **0.19.2**, immutable plugin-release commit        |
| HVE Core    | **3.2.2**, at the commit validated by Squad 0.19.2 |
| Copilot CLI | **1.0.105**                                        |
| Node.js     | **26.13.0**, latest stable release on 2026-11-02   |
| Python      | Python 3.12                                        |
| C#          | .NET 10 SDK, including the ASP.NET Core runtime    |
| PowerShell  | Latest stable release, checked to be at least 7.4  |
| GitHub CLI  | Latest stable release at image build               |

The container runs as the non-root `vscode` user. It also configures the
Copilot Chat, Python, C# Dev Kit, and PowerShell VS Code extensions.

## Base Image Choice

The official `mcr.microsoft.com/devcontainers/base:1-ubuntu-24.04` image is
the best fit for this workshop. It provides the standard devcontainer user
and utilities, and its glibc is compatible with APM's standalone binaries.

GitHub's [Universal image](https://github.com/devcontainers/images/tree/main/src/universal)
already includes many languages, but also includes unrelated stacks and
data-science tools. A language-specific image favors one stack without
removing the need to install the others. Building an operating-system image
from scratch is unnecessary here.

Official Dev Container Features install Node.js, Python, .NET, PowerShell,
Copilot CLI, and GitHub CLI. The small
[.devcontainer/Dockerfile](.devcontainer/Dockerfile) handles the pinned APM
binary and frozen plugin sources. Although community APM Features exist,
this recipe uses a checksummed release download with no unpinned fallback.

## Plugin Packaging

Both plugin sources are baked into `/opt/hve/marketplace`:

- Squad plugin commit: `66ba027c55b395cc026751606ae8dbc67c401c64`
- Matching HVE Core commit: `f60b057466bbdc79b78abcedfdda6b02f7740e3a`

The release marketplace's Squad entry originally points to `main`, even at
the v0.19.2 tag. [.devcontainer/prepare-plugins.sh](.devcontainer/prepare-plugins.sh)
replaces the remote sources with frozen local paths, validates the release
pairing, and checks the manifests' component paths. Upstream agents, skills,
hooks, MCP configuration, and attribution files are retained.

At container creation,
[.devcontainer/setup-plugins.sh](.devcontainer/setup-plugins.sh) registers
this local marketplace, installs **only Squad**, and enables the HVE Core
entry already bundled in it. A Squad-only install leaves that Core entry
disabled, so enabling it is necessary; a second Core install is not.

VS Code registers the same local plugin roots explicitly through
`chat.pluginLocations`. This also works with live marketplace plugins that
do not create a CLI plugin-copy directory. No separate HVE Core extension
or independently updated Core plugin is installed.

> [!IMPORTANT]
> APM must remain at **0.29.0**, not 0.29.1. The Squad release documents
> dependency-install regressions in APM 0.29.1 and 0.30.0. Plugin installation
> does not need APM, but the pinned CLI is available for workshop exercises.

## Join the Workshop

You need a GitHub account with Copilot access. Local development also needs
Docker, VS Code, and the Dev Containers extension. Codespaces needs no local
Docker installation.

1. Open the event repository in Codespaces, or clone it and run
   **Dev Containers: Reopen in Container** in VS Code.
2. Wait for the creation check to report that the workshop tools and plugins
   are ready.
3. Sign in to GitHub Copilot in VS Code. For terminal use, run `copilot` and
   complete `/login` when required, using your own account.
4. In the Copilot Chat agents picker, select **Squad Coach** to choose your
   setup, or **Squad Coordinator** to initialize a squad. In Copilot CLI,
   use `/agent` to select the corresponding agent.

With Squad Coordinator selected, send:

```text
init
```

Confirm the proposed team, then send your work request separately. No team
is initialized automatically by the container.

To check the environment again:

```bash
bash /usr/local/share/hve/verify.sh
copilot plugin list
```

> [!NOTE]
> Each attendee supplies their own authentication. No tokens, login state,
> or personal Copilot configuration are baked into the image. Copilot usage
> and Codespaces may incur charges; C# Dev Kit has its own licensing terms.
> Plugins include executable hooks and MCP servers, so review their sources
> and trust prompts. Service-specific workflows still need their own access.

The Squad plugin also registers its release-pinned MCP server,
`@hve-squad/mcp@0.9.1`. Its first invocation may download npm dependencies.
Copilot model access requires network connectivity.

## Publish and Share

The [publication workflow](.github/workflows/devcontainer.yml) builds the
complete devcontainer, including Features and image metadata. It lints the
scripts and guide, then runs setup twice to check repeatability before
publishing. Pull requests are validated without registry-write permissions.

1. Publish this repository to GitHub and enable GitHub Actions. Mark it as
   a template repository to let attendees create their own copies.
2. In **Actions**, choose **Workshop Dev Container**, then **Run workflow**.
   Use `0.19.2` as the initial image tag, or choose a distinct event tag.
3. The workflow publishes `ghcr.io/<owner>/<repository>:<tag>`, with the
   repository name lowercased. It uses the workflow's `GITHUB_TOKEN`; no
   personal registry token is needed.
4. In the package settings, make the image **public** before sharing it
   with attendees who should pull it without registry authentication.
5. The default configuration pulls the published image. Share its
   **Code > Codespaces** entry or a `codespaces.new/<owner>/<repository>` link.

This template publishes to `ghcr.io/jmservera/hve-squad-codespace:0.19.2`.
The maintenance recipe is
[.devcontainer/build/devcontainer.json](.devcontainer/build/devcontainer.json);
the publication workflow builds that configuration rather than the attendee
configuration. On a fork, the image name and source label follow the fork's
repository when its publication workflow runs.

The publication workflow targets **Linux/amd64**, matching Codespaces.
Native ARM64 builds have not been validated; attendees with ARM laptops
can use Codespaces.

## Reuse the Published Image

The default [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json)
pulls the published image. Another consuming repository needs only:

```json
{
  "name": "HVE Workshop",
  "image": "ghcr.io/jmservera/hve-squad-codespace:0.19.2",
  "remoteUser": "vscode",
  "waitFor": "postCreateCommand"
}
```

Plugin setup, environment settings, and VS Code customizations travel in
the image's `devcontainer.metadata` label. Do not add the language Features
again; they are already installed.

For an event freeze, reference the published image's `@sha256:...` digest
instead of a mutable tag. This template already pins the verified image:

```text
sha256:0cedaf9d1556f2f28354ac995eff2b424bb4b98b98647219248f62b85dc63f00
```

The feature lockfile pins Feature installation
code, but `latest` language options still resolve at build time. An image
digest freezes the complete workshop environment.

The published image passed an anonymous GHCR pull, metadata validation,
fresh container creation, and repeated plugin setup. Its runtime checks
reported APM 0.29.0, Copilot CLI 1.0.105, Python 3.12.16, Node.js 26.13.0,
.NET SDK 10.0.403, and PowerShell 7.6.9. Both Squad 0.19.2 and its Core 3.2.2
companion were enabled. The
[publication run](https://github.com/jmservera/hve-squad-codespace/actions/runs/41433117833)
contains the build and smoke-test evidence.

## Local Validation and Updates

Build the complete image with the Dev Container CLI, not `docker build`
alone: Docker does not process the `features` section.

```bash
shellcheck .devcontainer/*.sh
npx --yes @devcontainers/cli@0.90.0 build \
   --workspace-folder . --config .devcontainer/build/devcontainer.json \
   --image-name hve-squad-workshop:0.19.2
npx --yes @devcontainers/cli@0.90.0 up --workspace-folder .
npx --yes @devcontainers/cli@0.90.0 exec --workspace-folder . \
  bash /usr/local/share/hve/verify.sh
```

APM, Squad, Core, Copilot CLI, and Node.js are deliberately pinned. Update them in
the recipe, rebuild, rerun the checks, and publish a new event image rather
than updating attendees' plugins independently. The Core commit must match
the selected Squad release's marketplace. Resolve Node.js from the official
stable release index before advancing its pin; a floating `latest` Feature
option can select prereleases. Rebuild without cache to refresh the remaining
floating runtimes before publishing a new image.

Before an event, verify agent visibility and a small authenticated workflow
using an attendee account. Installation checks do not exercise live models,
organization policy, or service-specific connections.

## References

- [GitHub devcontainer introduction](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers)
- [Official and community Dev Container Features](https://containers.dev/features)
- [APM documentation](https://microsoft.github.io/apm/)
- [HVE Squad v0.19.2](https://github.com/Peter-N91/hve-squad/tree/v0.19.2)
- [Squad plugin v0.19.2](https://github.com/Peter-N91/hve-squad-plugin/tree/v0.19.2)
- [VS Code agent plugins](https://code.visualstudio.com/docs/copilot/customization/agent-plugins)
