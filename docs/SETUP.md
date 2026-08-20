# Environment Setup

## Scope

This document prepares a Debian 13 `amd64` host to validate, build, and test the images in this repository.

**Out of scope:** Replacing an existing Docker installation, rootless Docker, Docker Hub account administration, and non-`amd64` image builds.

## Platform Requirements

The published mdBook image is `linux/amd64`. The three EPICS images bake `EPICS_HOST_ARCH=linux-x86_64`, so the verified host scope is Debian 13 on `amd64`.

Confirm the host architecture:

```bash
dpkg --print-architecture
```

Expected output:

```
amd64
```

## Install Validation Packages

Install the commands used by `make check`:

```bash
sudo apt update
sudo apt install bash ca-certificates curl git make ruby shellcheck yamllint
```

## Install Docker Engine

This procedure uses Docker's Debian `apt` repository [1]. It is intended for a new host. Review Docker's conflicting-package guidance before replacing another Docker installation.

Install the repository prerequisites and key:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Open the Docker repository definition as root:

```bash
sudoedit /etc/apt/sources.list.d/docker.sources
```

Set its contents to:

```text
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
```

Install Docker Engine and its CLI plugins:

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify that the service is running and the engine can start a container:

```bash
sudo systemctl status docker --no-pager
sudo docker run --rm hello-world
```

## Grant User Access to Docker

The Docker socket is owned by `root` and the `docker` group. Membership in this group grants root-level control of the host [2]. Add only trusted users:

```bash
sudo usermod -aG docker "$USER"
```

End the current login session and start a new one. A session created before the group change retains its old supplementary groups.

Verify the new session without `sudo`:

```bash
id -nG
docker version
docker run --rm hello-world
```

The group list must contain `docker`, and `docker version` must show both Client and Server sections.

## Configure a Proxy

Skip this section when the host reaches Docker Hub and build dependencies directly. A proxied host needs two independent settings:

| Traffic | Configuration | Applies to |
|---|---|---|
| Docker daemon | systemd drop-in | Registry pull and push operations |
| Docker client | `~/.docker/config.json` | Proxy arguments for new builds and containers |

### Docker Daemon Proxy

Docker supports proxy environment variables in a systemd drop-in [3]. Create the directory and open the file as root:

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudoedit /etc/systemd/system/docker.service.d/http-proxy.conf
```

Use site values in place of the examples:

When an authenticated proxy URL contains percent-encoded characters, double each `%` as `%%` in this systemd drop-in [3]. This escaping applies only to the drop-in; use normal URL encoding in `~/.docker/config.json`.

```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:3128"
Environment="HTTPS_PROXY=http://proxy.example.com:3128"
Environment="NO_PROXY=localhost,127.0.0.1,.example.internal"
```

Apply and verify the service configuration:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl show --property=Environment docker
docker pull hello-world
```

The `systemctl show` output can expose proxy credentials. Do not copy it into logs, issues, or chat when the proxy URL contains authentication data.

### Docker Client Proxy

Docker reads build and container proxy settings from `~/.docker/config.json` [4]. Create the directory if needed:

```bash
mkdir -p "$HOME/.docker"
chmod 700 "$HOME/.docker"
```

Merge the `proxies` object into the existing JSON. Preserve existing keys such as `auths`, `credsStore`, and `credHelpers`.

```json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.example.com:3128",
      "httpsProxy": "http://proxy.example.com:3128",
      "noProxy": "localhost,127.0.0.1,.example.internal"
    }
  }
}
```

Validate the JSON and restrict access:

```bash
ruby -rjson -e 'JSON.parse(File.read(File.expand_path("~/.docker/config.json")))'
chmod 600 "$HOME/.docker/config.json"
```

No daemon restart is required. The settings apply only to containers and builds created after the file is saved. Proxy values can be stored in container metadata, so treat authenticated proxy URLs as sensitive [4].

## Build the Repository

Clone the repository and enter it:

```bash
git clone https://github.com/jeonghanlee/Dockerfiles.git
cd Dockerfiles
```

Verify the commands used by repository validation:

```bash
make check-tools
```

Run source validation and preview every configured image build:

```bash
make check
```

Build and verify one EPICS image through the normal path:

```bash
make build.debian13
make gate.debian13
```

The build must complete its package installation and Git fetches. The gate must report all 11 checks as passing.

Build the documentation with the fixed mdBook image:

```bash
make docs
```

The command creates `public/index.html` as the current user.

## References

[1] Docker, "Install Docker Engine on Debian." [Online]. Available: https://docs.docker.com/engine/install/debian/ [Accessed: Aug. 19, 2026].

[2] Docker, "Linux post-installation steps for Docker Engine." [Online]. Available: https://docs.docker.com/engine/install/linux-postinstall/ [Accessed: Aug. 19, 2026].

[3] Docker, "Daemon proxy configuration." [Online]. Available: https://docs.docker.com/engine/daemon/proxy/ [Accessed: Aug. 19, 2026].

[4] Docker, "Use a proxy server with the Docker CLI." [Online]. Available: https://docs.docker.com/engine/cli/proxy/ [Accessed: Aug. 19, 2026].
