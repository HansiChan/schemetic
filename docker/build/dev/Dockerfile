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
# Keep the logic simple and explicit.
ARG FLINK_VERSION=1.20.1
ARG SCALA_BINARY=2.12
ARG LOG4J_VERSION=2.17.1
# Flink shaded Hadoop jar (download from the exact location requested)
# NOTE: mvnrepository.com is a catalog; use the direct Maven Central jar URL for that page.
ARG FLINK_SHADED_HADOOP_URL="https://repository.cloudera.com/repository/cloudera-repos/org/apache/flink/flink-shaded-hadoop-3/3.1.1.7.2.9.0-173-9.0/flink-shaded-hadoop-3-3.1.1.7.2.9.0-173-9.0.jar"

# Apache Paimon — use the exact snapshot URLs requested by the user
ARG PAIMON_FLINK_JAR_URL="https://repository.apache.org/content/groups/snapshots/org/apache/paimon/paimon-flink-1.20/1.4-SNAPSHOT/paimon-flink-1.20-1.4-20251031.003016-47.jar"
ARG PAIMON_S3_JAR_URL="https://repository.apache.org/content/groups/snapshots/org/apache/paimon/paimon-s3/1.4-SNAPSHOT/paimon-s3-1.4-20251031.003016-47.jar"
ARG PAIMON_FLINK_MAJOR=1.20
ARG PAIMON_VERSION=1.4

RUN set -eux; \
    PLUGINS_DIR=/opt/flink/flink-plugins; \
    mkdir -p "${PLUGINS_DIR}"; \
    BASE_MVN="https://repo1.maven.org/maven2"; \
    download() { url="$1"; out="$2"; echo "Downloading: $url"; curl -fL --retry 3 --retry-delay 2 -o "$out" "$url"; }; \
    # Only the three user-specified artifacts (simple and explicit)
    download "$FLINK_SHADED_HADOOP_URL" "${PLUGINS_DIR}/$(basename "$FLINK_SHADED_HADOOP_URL")"; \
    download "$PAIMON_FLINK_JAR_URL" "${PLUGINS_DIR}/$(basename "$PAIMON_FLINK_JAR_URL")"; \
    download "$PAIMON_S3_JAR_URL" "${PLUGINS_DIR}/$(basename "$PAIMON_S3_JAR_URL")"; \
    # Other required Flink and Log4j artifacts from Maven Central
    download "$BASE_MVN/org/apache/flink/flink-clients/${FLINK_VERSION}/flink-clients-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-clients-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-connector-datagen/${FLINK_VERSION}/flink-connector-datagen-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-connector-datagen-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-dist/${FLINK_VERSION}/flink-dist-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-dist-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-json-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-kubernetes/${FLINK_VERSION}/flink-kubernetes-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-kubernetes-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-python/${FLINK_VERSION}/flink-python-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-python-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-s3-fs-hadoop/${FLINK_VERSION}/flink-s3-fs-hadoop-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-s3-fs-hadoop-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-scala_${SCALA_BINARY}/${FLINK_VERSION}/flink-scala_${SCALA_BINARY}-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-scala_${SCALA_BINARY}-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-sql-gateway/${FLINK_VERSION}/flink-sql-gateway-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-sql-gateway-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-table-api-java-uber/${FLINK_VERSION}/flink-table-api-java-uber-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-table-api-java-uber-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-table-planner-loader/${FLINK_VERSION}/flink-table-planner-loader-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-table-planner-loader-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/flink/flink-table-runtime/${FLINK_VERSION}/flink-table-runtime-${FLINK_VERSION}.jar" "${PLUGINS_DIR}/flink-table-runtime-${FLINK_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/logging/log4j/log4j-1.2-api/${LOG4J_VERSION}/log4j-1.2-api-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-1.2-api-${LOG4J_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/logging/log4j/log4j-api/${LOG4J_VERSION}/log4j-api-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-api-${LOG4J_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/logging/log4j/log4j-core/${LOG4J_VERSION}/log4j-core-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-core-${LOG4J_VERSION}.jar"; \
    download "$BASE_MVN/org/apache/logging/log4j/log4j-slf4j-impl/${LOG4J_VERSION}/log4j-slf4j-impl-${LOG4J_VERSION}.jar" "${PLUGINS_DIR}/log4j-slf4j-impl-${LOG4J_VERSION}.jar"

# Traceability (generic, overridable)
ARG LABEL_SOURCE=""
ARG LABEL_BASE_NAME="flink:1.20.1-scala_2.12"
LABEL org.opencontainers.image.source="${LABEL_SOURCE}" \
      org.opencontainers.image.base.name="${LABEL_BASE_NAME}"
