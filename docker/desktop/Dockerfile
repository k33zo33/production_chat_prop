ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter@sha256:00a00f16768db672361fb5b79396b2748b75391c9d3bd9a33fc40b257ee94ef0

FROM ${FLUTTER_IMAGE} AS build

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    clang \
    cmake \
    libgtk-3-dev \
    liblzma-dev \
    ninja-build \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter config --enable-linux-desktop \
  && flutter pub get

COPY analysis_options.yaml .metadata ./
COPY docs/fixtures/ docs/fixtures/
COPY lib/ lib/
COPY linux/ linux/
RUN flutter build linux --release

FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    dbus-x11 \
    fluxbox \
    fonts-noto-color-emoji \
    fonts-noto-core \
    libegl1 \
    libgles2 \
    libgl1 \
    libgl1-mesa-dri \
    libgtk-3-0 \
    liblzma5 \
    libsecret-1-0 \
    libstdc++6 \
    novnc \
    websockify \
    x11-utils \
    x11vnc \
    xvfb \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 10001 appuser \
  && mkdir -p /home/appuser/.config \
  && chown -R appuser:appuser /home/appuser

WORKDIR /app
# Flutter Linux currently emits the desktop bundle under build/linux/x64.
COPY --from=build --chown=appuser:appuser /app/build/linux/x64/release/bundle/ /app/
COPY --chown=appuser:appuser docker/desktop/entrypoint.sh /usr/local/bin/production-chat-prop-desktop
RUN chmod +x /usr/local/bin/production-chat-prop-desktop

USER appuser
ENV DISPLAY=:99
ENV HOME=/home/appuser
ENV VNC_GEOMETRY=1440x900x24
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080

EXPOSE 5900 6080

ENTRYPOINT ["production-chat-prop-desktop"]
