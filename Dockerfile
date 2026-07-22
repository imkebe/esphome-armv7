ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim-bookworm

ARG BUILD_VERSION

# PioArduino's bundled CMake is linked to OpenSSL 1.1, while Bookworm supplies
# OpenSSL 3. Keep the compatibility runtime package pinned here.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        curl \
        git \
        ninja-build \
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
    && curl -fsSL -o /tmp/libssl1.1.deb \
        https://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u8_armhf.deb \
    && apt-get install -y --no-install-recommends /tmp/libssl1.1.deb \
    && rm -f /tmp/libssl1.1.deb \
    && rm -rf /var/lib/apt/lists/*

# ESP-IDF publishes ARMv7-only binary wheels (including tree-sitter-c) here.
# ESPHome's native ESP-IDF installer inherits pip's environment but does not add
# this index itself; without it a clean ARMv7 compile cannot satisfy its
# binary-only tree-sitter-c requirement.
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_EXTRA_INDEX_URL=https://dl.espressif.com/pypi \
    PLATFORMIO_SETTING_ENABLE_TELEMETRY=No \
    PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL=1000000

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && pip install --no-cache-dir esphome-device-builder==1.1.0

# PioArduino creates this isolated environment for ESP-IDF tooling. Install its
# complete dependency set while the ARMv7 build headers are still present.
# Otherwise it tries to compile cffi during the first firmware build, after this
# image has already removed libffi-dev to stay lean. PioArduino also addresses
# Ninja through its package path even though Debian's ninja-build provides it.
RUN mkdir -p /root/.platformio \
    && python -m venv /root/.platformio/penv \
    && /root/.platformio/penv/bin/python -m pip install --no-cache-dir --upgrade \
        pip uv \
        "pioarduino>=6.1.19" \
        "littlefs-python>=0.16.0" \
        "fatfs-ng>=0.1.14" \
        "pyyaml>=6.0.2" \
        "rich-click>=1.8.6" \
        "zopfli>=0.2.2" \
        "intelhex>=2.3.0" \
        "rich>=14.0.0" \
        "cryptography>=45.0.3" \
        "certifi>=2025.8.3" \
        "ecdsa>=0.19.1" \
        "bitstring>=4.3.1" \
        "reedsolo>=1.5.3,<1.8" \
        "esp-idf-size>=2.0.0" \
        "esp-coredump>=1.14.0" \
        "pyelftools>=0.32" \
    && mkdir -p /root/.platformio/packages/tool-ninja \
    && ln -s /usr/bin/ninja /root/.platformio/packages/tool-ninja/ninja \
    && rm -rf /root/.cache

# ESP-IDF creates a separate environment under /config at first firmware
# compile. Its esptool dependency may build cffi from source on ARMv7, so
# ffi.h must remain available in the final runtime image.
COPY . /esphome
RUN pip install --no-cache-dir /esphome \
    && platformio settings set enable_telemetry No \
    && platformio settings set check_platformio_interval 1000000 \
    && mkdir -p /piolibs \
    && apt-get purge -y --auto-remove build-essential libjpeg62-turbo-dev zlib1g-dev libfreetype-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/* /root/.cache

# Set the prefixes in the image environment (not only in the entrypoint) so
# dashboard, direct CLI, and docker-exec invocations use the same persistent
# ESP-IDF installation.
ENV ESPHOME_ESP_IDF_PREFIX=/config/.esphome/idf \
    ESPHOME_SDK_NRF_PREFIX=/config/.esphome/sdk-nrf

LABEL org.opencontainers.image.title="ESPHome ARMv7" \
      org.opencontainers.image.source="https://github.com/imkebe/esphome-armv7" \
      org.opencontainers.image.version="${BUILD_VERSION}"

EXPOSE 6052
HEALTHCHECK --interval=30s --timeout=30s \
    CMD curl --fail http://localhost:6052/version -A "HealthCheck" || exit 1

COPY docker/docker_entrypoint.sh /entrypoint.upstream.sh
COPY docker/armv7_entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /config
WORKDIR /config
ENTRYPOINT ["/entrypoint.sh"]
CMD ["dashboard", "/config"]
