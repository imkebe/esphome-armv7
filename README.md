# ESPHome ARMv7

An Orange Pi ARMv7 Docker build of ESPHome. The build checks out the requested
official ESPHome release and applies the ARMv7 Dockerfile in this repository.

## Build

```sh
./build.sh
```

Defaults:

- `ESPHOME_VERSION=2026.6.5`
- `IMAGE_NAME=esphome-armv7`
- upstream source: `https://github.com/esphome/esphome.git`

The result is `esphome-armv7:2026.6.5`.

## Publish to GHCR

Authenticate first with a GitHub classic PAT that has `write:packages`, then:

```sh
docker login ghcr.io -u imkebe
./push.sh
```

This publishes both `ghcr.io/imkebe/esphome-armv7:2026.6.5` and `:latest`.

## Run

```sh
docker run -d --name esphome --restart always --network host \
  -v /var/lib/docker/volumes/esphome/_data:/config \
  -v /etc/localtime:/etc/localtime:ro \
  ghcr.io/imkebe/esphome-armv7:2026.6.5
```

The container serves the dashboard on port 6052 and persists its state in
`/config`.
