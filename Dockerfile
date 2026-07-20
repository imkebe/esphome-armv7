ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim-bookworm

ARG BUILD_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        curl \
        git \
        libusb-1.0-0 \
        libssl3 \
        libffi8 \
        libjpeg62-turbo \
        zlib1g \
        libfreetype6 \
        liblcms2-2 \
        libwebp7 \
        libharfbuzz0b \
        libfribidi0 \
        libxcb1 \
        libjpeg62-turbo-dev \
        zlib1g-dev \
        libfreetype-dev \
        liblcms2-dev \
        libwebp-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libxcb1-dev \
        libffi-dev \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PLATFORMIO_SETTING_ENABLE_TELEMETRY=No \
    PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL=1000000

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && pip install --no-cache-dir esphome-device-builder==1.1.0

# PioArduino creates this isolated environment for ESP-IDF tooling. Seed its
# bootstrap packages here: it must not rely on the global ESPHome environment.
RUN mkdir -p /root/.platformio \
    && python -m venv /root/.platformio/penv \
    && /root/.platformio/penv/bin/python -m pip install --no-cache-dir --upgrade \
        pip uv certifi packaging \
    && rm -rf /root/.cache

COPY . /esphome
RUN pip install --no-cache-dir /esphome \
    && platformio settings set enable_telemetry No \
    && platformio settings set check_platformio_interval 1000000 \
    && mkdir -p /piolibs \
    && apt-get purge -y --auto-remove build-essential libjpeg62-turbo-dev zlib1g-dev libfreetype-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libffi-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/* /root/.cache

LABEL org.opencontainers.image.title="ESPHome ARMv7" \
      org.opencontainers.image.source="https://github.com/imkebe/esphome-armv7" \
      org.opencontainers.image.version="${BUILD_VERSION}"

EXPOSE 6052
HEALTHCHECK --interval=30s --timeout=30s \
    CMD curl --fail http://localhost:6052/version -A "HealthCheck" || exit 1

COPY docker/docker_entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /config
WORKDIR /config
ENTRYPOINT ["/entrypoint.sh"]
CMD ["dashboard", "/config"]
