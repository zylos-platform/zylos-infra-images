ARG DEBEZIUM_VERSION=3.5.2.Final
ARG CONFLUENT_VERSION=8.0.0

FROM ubuntu:24.04 AS plugins
ARG DEBEZIUM_VERSION
ARG CONFLUENT_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Debezium MongoDB connector
RUN mkdir -p /staging/debezium-connector-mongodb && \
    curl -fsSL "https://repo1.maven.org/maven2/io/debezium/debezium-connector-mongodb/${DEBEZIUM_VERSION}/debezium-connector-mongodb-${DEBEZIUM_VERSION}-plugin.tar.gz" \
    | tar -xz --strip-components=1 -C /staging/debezium-connector-mongodb && \
    rm -f /staging/debezium-connector-mongodb/kafka-clients-*.jar \
          /staging/debezium-connector-mongodb/connect-api-*.jar

# Confluent Avro converter (curated Confluent Hub zip)
RUN mkdir -p /staging/confluent-avro-converter && \
    curl -fsSL -o /tmp/avro.zip \
      "https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-avro-converter/versions/${CONFLUENT_VERSION}/confluentinc-kafka-connect-avro-converter-${CONFLUENT_VERSION}.zip" && \
    unzip -q /tmp/avro.zip -d /tmp/avro && \
    cp /tmp/avro/*/lib/*.jar /staging/confluent-avro-converter/ && \
    rm -rf /tmp/avro /tmp/avro.zip

# JAR-hell tripwire
RUN found="$(find /staging \
        \( -name 'kafka-clients-*.jar' \
        -o -name 'connect-api-*.jar' \
        -o -name 'connect-runtime-*.jar' \
        -o -name 'connect-json-*.jar' \) )" && \
    if [ -n "$found" ]; then \
        echo "FORBIDDEN RUNTIME JARS IN PLUGIN PATH:"; \
        echo "$found"; \
        exit 1; \
    fi

FROM quay.io/strimzi/kafka:1.1.0-kafka-4.3.0
USER root:root
COPY --from=plugins --chown=1001:0 /staging/ /opt/kafka/plugins/
USER 1001
