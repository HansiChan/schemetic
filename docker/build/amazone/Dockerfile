# Stage 1: Get Flink from official image
FROM flink:1.20.1-scala_2.12 AS flink-base

# Stage 2: Build on Amazon Linux 2023
FROM amazonlinux:2023

# Build-time versions
ARG PYTHON_VERSION=3.11
ARG UV_VERSION=v0.4.20

# Base tools and JDK - install first before copying large Flink directory
RUN dnf update -y && dnf install -y --allowerasing \
    curl ca-certificates findutils gcc gcc-c++ make tar gzip shadow-utils \
    java-17-amazon-corretto-devel \
 && dnf clean all

# Copy Flink from official image
COPY --from=flink-base /opt/flink /opt/flink
COPY --from=flink-base /docker-entrypoint.sh /docker-entrypoint.sh

# Set Flink and Java environment variables (use Amazon Corretto JDK)
ENV FLINK_HOME=/opt/flink
ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
ENV PATH=$FLINK_HOME/bin:$JAVA_HOME/bin:$PATH

# Install uv and Python dependencies via uv
RUN set -eux; \
    curl -LsSf --retry 3 --retry-delay 2 https://astral.sh/uv/install.sh -o /tmp/uv-install.sh; \
    sh /tmp/uv-install.sh --version ${UV_VERSION} || sh /tmp/uv-install.sh; \
    ln -s /root/.local/bin/uv /usr/local/bin/uv; \
    # Install CPython via uv and relocate it to a world-readable path
    uv python install ${PYTHON_VERSION}; \
    PYBIN=$(uv python find ${PYTHON_VERSION} | head -n1); \
    PYROOT=$(dirname $(dirname "$PYBIN")); \
    cp -a "$PYROOT" /opt/python; \
    chmod -R a+rx /opt/python; \
    ln -sf /opt/python/bin/python3 /usr/local/bin/python3; \
    # Create a dedicated virtualenv for app deps using the relocated interpreter
    /opt/python/bin/python3 -m venv /opt/venv; \
    find /opt/venv -type d -exec chmod 0755 {} \; ; \
    find /opt/venv -type f -name 'python*' -exec chmod 0755 {} \;

COPY docker/build/amazone/requirements.txt /tmp/requirements.txt
RUN echo "Using JAVA_HOME=$JAVA_HOME" \
    && uv pip install --python /opt/venv/bin/python3 --no-cache -r /tmp/requirements.txt \
    && echo "Upgrading vulnerable packages..." \
    && uv pip install --python /opt/venv/bin/python3 --no-cache --upgrade \
        "protobuf>=4.25.8" \
        "pyarrow>=14.0.1" \
    && find /opt/venv -type d -exec chmod 0755 {} \; \
    && find /opt/venv -type f -name 'python*' -exec chmod 0755 {} \;

# Prepare directories: SQL, runtime code, and (empty) plugins
RUN mkdir -p /opt/flink/sql /opt/flink/usrcode /opt/flink/flink-plugins

# Copy pipeline SQL and Python entry (from repo src/)
COPY src/sql/pipeline.sql /opt/flink/sql/pipeline.sql
COPY src/app.py /opt/flink/usrcode/app.py

# Pre-bake truststore with MinIO CA so runtime pods do not need init containers
COPY docker/build/amazone/bootstrap/register-ca.sh /opt/bootstrap/register-ca.sh
COPY docker/build/amazone/minio-ca.crt /tmp/minio-ca.crt
RUN set -eux; \
    chmod +x /opt/bootstrap/register-ca.sh; \
    mkdir -p /etc/ssl/truststore; \
    CA_FILE=/tmp/minio-ca.crt TARGET_TRUSTSTORE=/etc/ssl/truststore/cacerts STOREPASS=changeit /opt/bootstrap/register-ca.sh; \
    rm -f /tmp/minio-ca.crt

# Pre-baked plugin jars are copied from the build context into /opt/flink/lib.
COPY flink-plugins/ /opt/flink/lib/

RUN set -eux; \
    if ! getent group 9999 >/dev/null; then groupadd --gid 9999 flink; fi; \
    if ! getent passwd 9999 >/dev/null; then useradd --uid 9999 --gid 9999 -m -s /bin/bash flink; fi; \
    chown -R flink:flink /opt/flink /opt/venv /opt/python

# Traceability (generic, overridable)
ARG LABEL_SOURCE=""
ARG LABEL_BASE_NAME="amazonlinux:2023"
LABEL org.opencontainers.image.source="${LABEL_SOURCE}" \
      org.opencontainers.image.base.name="${LABEL_BASE_NAME}"