FROM quay.io/strimzi/kafka:1.1.0-kafka-4.3.0

USER root:root

# Debezium MongoDB connector
ARG DEBEZIUM_VERSION=3.5.0.Final
RUN mkdir -p /opt/kafka/plugins/debezium-connector-mongodb && \
    curl -fsSL "https://repo1.maven.org/maven2/io/debezium/debezium-connector-mongodb/${DEBEZIUM_VERSION}/debezium-connector-mongodb-${DEBEZIUM_VERSION}-plugin.tar.gz" \
    | tar -xz --strip-components=1 -C /opt/kafka/plugins/debezium-connector-mongodb

# Confluent Avro converter
ARG CONFLUENT_VERSION=8.0.0

# Download Avro Converter AND run JAR-hell tripwire in a single layer
RUN mkdir -p /opt/kafka/plugins/confluent-avro-converter && \
    curl -fsSL -o /tmp/avro.zip "https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-avro-converter/versions/${CONFLUENT_VERSION}/confluentinc-kafka-connect-avro-converter-${CONFLUENT_VERSION}.zip" && \
    unzip -q /tmp/avro.zip -d /tmp/avro && \
    cp /tmp/avro/*/lib/*.jar /opt/kafka/plugins/confluent-avro-converter/ && \
    rm -rf /tmp/avro /tmp/avro.zip && \
    found="$(find /opt/kafka/plugins \
        \( -name 'kafka-clients-*.jar' \
        -o -name 'connect-api-*.jar' \
        -o -name 'connect-runtime-*.jar' \
        -o -name 'connect-json-*.jar' \) )" && \
    if [ -n "$found" ]; then \
        echo "FORBIDDEN RUNTIME JARS IN PLUGIN PATH:"; \
        echo "$found"; \
        exit 1; \
    fi

USER 1001
