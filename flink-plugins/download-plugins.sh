#!/bin/bash
#
# Flink Plugins Download Script
# This script downloads all required Flink plugins and connectors
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Flink version
FLINK_VERSION="1.20.2"
PAIMON_VERSION="1.3.1"
HADOOP_VERSION="3.4.0"

# Maven repository base URLs
MAVEN_CENTRAL="https://repo1.maven.org/maven2"
APACHE_REPO="https://repo.maven.apache.org/maven2"

echo "==============================================="
echo "  Flink Plugins Download Script"
echo "  Flink Version: ${FLINK_VERSION}"
echo "  Paimon Version: ${PAIMON_VERSION}"
echo "==============================================="
echo ""

# Function to download a file
download_jar() {
    local url="$1"
    local filename="$2"
    
    if [ -f "$filename" ]; then
        echo "[SKIP] $filename already exists"
    else
        echo "[DOWNLOAD] $filename"
        curl -fSL -o "$filename" "$url" || {
            echo "[ERROR] Failed to download $filename"
            return 1
        }
        echo "[OK] $filename downloaded successfully"
    fi
}

echo ">>> Downloading Flink Core Components..."
echo ""

# Flink SQL Client
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-sql-client/${FLINK_VERSION}/flink-sql-client-${FLINK_VERSION}.jar" \
    "flink-sql-client-${FLINK_VERSION}.jar"

# Flink SQL Gateway
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-sql-gateway/${FLINK_VERSION}/flink-sql-gateway-${FLINK_VERSION}.jar" \
    "flink-sql-gateway-${FLINK_VERSION}.jar"

# Flink Table API Java Uber
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-table-api-java-uber/${FLINK_VERSION}/flink-table-api-java-uber-${FLINK_VERSION}.jar" \
    "flink-table-api-java-uber-${FLINK_VERSION}.jar"

# Flink Table Planner Loader
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-table-planner-loader/${FLINK_VERSION}/flink-table-planner-loader-${FLINK_VERSION}.jar" \
    "flink-table-planner-loader-${FLINK_VERSION}.jar"

# Flink Table Runtime
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-table-runtime/${FLINK_VERSION}/flink-table-runtime-${FLINK_VERSION}.jar" \
    "flink-table-runtime-${FLINK_VERSION}.jar"

echo ""
echo ">>> Downloading Flink Connectors..."
echo ""

# Flink Connector Datagen
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-connector-datagen/${FLINK_VERSION}/flink-connector-datagen-${FLINK_VERSION}.jar" \
    "flink-connector-datagen-${FLINK_VERSION}.jar"

# Flink JSON Format
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar" \
    "flink-json-${FLINK_VERSION}.jar"

# Flink Python
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-python/${FLINK_VERSION}/flink-python-${FLINK_VERSION}.jar" \
    "flink-python-${FLINK_VERSION}.jar"

# Flink S3 Filesystem (Hadoop)
download_jar "${MAVEN_CENTRAL}/org/apache/flink/flink-s3-fs-hadoop/${FLINK_VERSION}/flink-s3-fs-hadoop-${FLINK_VERSION}.jar" \
    "flink-s3-fs-hadoop-${FLINK_VERSION}.jar"

echo ""
echo ">>> Downloading Paimon Components..."
echo ""

# Paimon Flink Connector
download_jar "${MAVEN_CENTRAL}/org/apache/paimon/paimon-flink-1.20/${PAIMON_VERSION}/paimon-flink-1.20-${PAIMON_VERSION}.jar" \
    "paimon-flink-1.20-${PAIMON_VERSION}.jar"

# Paimon S3 Support
download_jar "${MAVEN_CENTRAL}/org/apache/paimon/paimon-s3/${PAIMON_VERSION}/paimon-s3-${PAIMON_VERSION}.jar" \
    "paimon-s3-${PAIMON_VERSION}.jar"

echo ""
echo ">>> Downloading Hadoop Components (required by Paimon)..."
echo ""

# Hadoop HDFS Client - required for org.apache.hadoop.hdfs.HdfsConfiguration
download_jar "${MAVEN_CENTRAL}/org/apache/hadoop/hadoop-hdfs-client/${HADOOP_VERSION}/hadoop-hdfs-client-${HADOOP_VERSION}.jar" \
    "hadoop-hdfs-client-${HADOOP_VERSION}.jar"

# Hadoop MapReduce Client Core - required for org.apache.hadoop.mapreduce.lib.input.FileInputFormat
download_jar "${MAVEN_CENTRAL}/org/apache/hadoop/hadoop-mapreduce-client-core/${HADOOP_VERSION}/hadoop-mapreduce-client-core-${HADOOP_VERSION}.jar" \
    "hadoop-mapreduce-client-core-${HADOOP_VERSION}.jar"

# Hadoop Common - required by mapreduce-client-core
download_jar "${MAVEN_CENTRAL}/org/apache/hadoop/hadoop-common/${HADOOP_VERSION}/hadoop-common-${HADOOP_VERSION}.jar" \
    "hadoop-common-${HADOOP_VERSION}.jar"

echo ""
echo "==============================================="
echo "  Download Complete!"
echo "==============================================="
echo ""
echo "Downloaded JARs:"
ls -lh *.jar 2>/dev/null || echo "No JAR files found"
