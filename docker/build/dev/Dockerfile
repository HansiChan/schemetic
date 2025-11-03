FROM flink:1.20.1-scala_2.12

# Build-time versions
ARG PYTHON_VERSION=3.11
ARG UV_VERSION=v0.4.20

# Base tools
RUN apt-get update && apt-get install -y \
    curl ca-certificates findutils build-essential openjdk-17-jdk-headless \
 && rm -rf /var/lib/apt/lists/*

# Install uv and Python dependencies via uv
RUN set -eux; \
    curl -LsSf --retry 3 --retry-delay 2 https://astral.sh/uv/install.sh -o /tmp/uv-install.sh; \
    sh /tmp/uv-install.sh --version ${UV_VERSION} || sh /tmp/uv-install.sh; \
    ln -s /root/.local/bin/uv /usr/local/bin/uv; \
    uv python install ${PYTHON_VERSION}; \
    PYBIN=$(uv python find ${PYTHON_VERSION} | head -n1); \
    # Create a dedicated virtualenv for app deps and expose it as system python3
    "$PYBIN" -m venv /opt/venv; \
    ln -sf /opt/venv/bin/python3 /usr/local/bin/python3

COPY docker/build/dev/requirements.txt /tmp/requirements.txt
RUN export JAVA_HOME=$(dirname $(dirname $(readlink -f $(command -v javac)))) \
    && echo "Using JAVA_HOME=$JAVA_HOME" \
    && uv pip install --python /opt/venv/bin/python3 --no-cache -r /tmp/requirements.txt

# Prepare directories: SQL, runtime code, and (empty) plugins
RUN mkdir -p /opt/flink/sql /opt/flink/usrcode /opt/flink/flink-plugins

# Copy pipeline SQL and Python entry (from repo src/)
COPY src/sql/pipeline.sql /opt/flink/sql/pipeline.sql
COPY src/app.py /opt/flink/usrcode/app.py

# Download required Flink plugins and dependencies into /opt/flink/flink-plugins
# You can override versions/URLs at build time with --build-arg if needed.
ARG FLINK_VERSION=1.20.1
ARG SCALA_BINARY=2.12
ARG KAFKA_VERSION=3.8.1
ARG LOG4J_VERSION=2.17.1
# Flink shaded Hadoop jar (explicit URL). Leave empty to skip.
ARG FLINK_SHADED_HADOOP_URL=""
# Apache Paimon version (release) and Flink compatibility
# Defaults use stable release artifacts from Maven Central.
ARG PAIMON_VERSION=1.4
ARG PAIMON_FLINK_MAJOR=1.20
# Optional explicit URLs for snapshot builds (leave empty to use release coordinates)
ARG PAIMON_FLINK_JAR_URL=""
ARG PAIMON_S3_JAR_URL=""

RUN set -eux; \
    PLUGINS_DIR=/opt/flink/flink-plugins; \
    mkdir -p "${PLUGINS_DIR}"; \
    BASE_MVN="https://repo1.maven.org/maven2"; \
    ALT_MVN1="https://repo.maven.apache.org/maven2"; \
    ALT_MVN2="https://maven.aliyun.com/repository/central"; \
    fetch() { \
      url="$1"; out="$2"; \
      echo "Downloading: $url"; \
      if curl -fL --retry 3 --retry-delay 2 -o "$out" "$url"; then \
        return 0; \
      fi; \
      path="$(echo "$url" | sed -E 's#https?://[^/]+##')"; \
      for base in "$ALT_MVN1" "$ALT_MVN2"; do \
        alt="$base$path"; echo "Retrying via mirror: $alt"; \
        if curl -fL --retry 3 --retry-delay 2 -o "$out" "$alt"; then \
          return 0; \
        fi; \
      done; \
      echo "ERROR: failed to download $url (and mirrors)"; \
      return 22; \
    }; \
    # Kafka Connect API
    fetch "$BASE_MVN/org/apache/kafka/connect-api/${KAFKA_VERSION}/connect-api-${KAFKA_VERSION}.jar" "${PLUGINS_DIR}/connect-api-${KAFKA_VERSION}.jar"; \
    # Flink core and connectors
    fetch "$BASE_MVN/org/apache/flink/flink-clients/${FLINK_VERSION}/flink-clients-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-clients-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-connector-datagen/${FLINK_VERSION}/flink-connector-datagen-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-connector-datagen-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-dist/${FLINK_VERSION}/flink-dist-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-dist-${FLINK_VERSION}.jar" || echo "flink-dist jar not found; continuing"; \
    fetch "$BASE_MVN/org/apache/flink/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-json-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-kubernetes/${FLINK_VERSION}/flink-kubernetes-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-kubernetes-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-python/${FLINK_VERSION}/flink-python-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-python-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-s3-fs-hadoop/${FLINK_VERSION}/flink-s3-fs-hadoop-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-s3-fs-hadoop-${FLINK_VERSION}.jar"; \
    # Scala API was removed in newer Flink; ignore if not found
    fetch "$BASE_MVN/org/apache/flink/flink-scala_${SCALA_BINARY}/${FLINK_VERSION}/flink-scala_${SCALA_BINARY}-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-scala_${SCALA_BINARY}-${FLINK_VERSION}.jar" || echo "flink-scala jar not found; continuing"; \
    # Flink shaded Hadoop from explicit URL (optional)
    if [ -n "$FLINK_SHADED_HADOOP_URL" ]; then \
      fetch "$FLINK_SHADED_HADOOP_URL" "${PLUGINS_DIR}/$(basename "$FLINK_SHADED_HADOOP_URL")"; \
    else \
      echo "Skipping shaded Hadoop jar (FLINK_SHADED_HADOOP_URL empty)"; \
    fi; \
    fetch "$BASE_MVN/org/apache/flink/flink-sql-gateway/${FLINK_VERSION}/flink-sql-gateway-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-sql-gateway-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-table-api-java-uber/${FLINK_VERSION}/flink-table-api-java-uber-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-table-api-java-uber-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-table-planner-loader/${FLINK_VERSION}/flink-table-planner-loader-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-table-planner-loader-${FLINK_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/flink/flink-table-runtime/${FLINK_VERSION}/flink-table-runtime-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-table-runtime-${FLINK_VERSION}.jar"; \
    # Log4j stack
    fetch "$BASE_MVN/org/apache/logging/log4j/log4j-1.2-api/${LOG4J_VERSION}/log4j-1.2-api-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-1.2-api-${LOG4J_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/logging/log4j/log4j-api/${LOG4J_VERSION}/log4j-api-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-api-${LOG4J_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/logging/log4j/log4j-core/${LOG4J_VERSION}/log4j-core-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-core-${LOG4J_VERSION}.jar"; \
    fetch "$BASE_MVN/org/apache/logging/log4j/log4j-slf4j-impl/${LOG4J_VERSION}/log4j-slf4j-impl-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-slf4j-impl-${LOG4J_VERSION}.jar"; \
    # Apache Paimon: use explicit URLs if provided (e.g., snapshots), else use release coordinates
    if [ -n "$PAIMON_FLINK_JAR_URL" ]; then \
      fetch "$PAIMON_FLINK_JAR_URL" "${PLUGINS_DIR}/$(basename "$PAIMON_FLINK_JAR_URL")"; \
    else \
      fetch "$BASE_MVN/org/apache/paimon/paimon-flink-${PAIMON_FLINK_MAJOR}/${PAIMON_VERSION}/paimon-flink-${PAIMON_FLINK_MAJOR}-${PAIMON_VERSION}.jar" "${PLUGINS_DIR}/paimon-flink-${PAIMON_FLINK_MAJOR}-${PAIMON_VERSION}.jar"; \
    fi; \
    if [ -n "$PAIMON_S3_JAR_URL" ]; then \
      fetch "$PAIMON_S3_JAR_URL" "${PLUGINS_DIR}/$(basename "$PAIMON_S3_JAR_URL")"; \
    else \
      fetch "$BASE_MVN/org/apache/paimon/paimon-s3/${PAIMON_VERSION}/paimon-s3-${PAIMON_VERSION}.jar" "${PLUGINS_DIR}/paimon-s3-${PAIMON_VERSION}.jar"; \
    fi

# Traceability (generic, overridable)
ARG LABEL_SOURCE=""
ARG LABEL_BASE_NAME="flink:1.20.1-scala_2.12"
LABEL org.opencontainers.image.source="${LABEL_SOURCE}" \
      org.opencontainers.image.base.name="${LABEL_BASE_NAME}"
