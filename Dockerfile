#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
FROM openjdk:8-jdk-alpine AS builder

RUN mkdir builddir
COPY . builddir
WORKDIR builddir
RUN ./gradlew publishToMavenLocal


FROM openjdk:8-jdk-alpine AS runner

ARG teller_port=2028
ARG jmx_port=9018
ARG jmx_prome_port=8088

ENV server.max-http-header-size=16384 \
    cassandra.clusterName="Test Cluster" \
    server.port=$teller_port

WORKDIR /tmp
COPY --from=builder /builddir/service/build/libs/service-0.1.0-BUILD-SNAPSHOT-boot.jar ./teller-service-boot.jar
COPY jmx_prometheus_javaagent-0.20.0.jar /tmp/jmx_prometheus_javaagent-0.20.0.jar
COPY jmx_config.yaml /tmp/jmx_config.yaml

# CMD ["java", "-jar", "teller-service-boot.jar"]
EXPOSE $jmx_prome_port
ENV JAVA_OPTS="-Dcom.sun.management.jmxremote \
               -Dcom.sun.management.jmxremote.port=$jmx_port \
               -Dcom.sun.management.jmxremote.rmi.port=$jmx_port \
               -Dcom.sun.management.jmxremote.authenticate=false \
               -Dcom.sun.management.jmxremote.ssl=false \
               -Djava.rmi.server.hostname=0.0.0.0"

ENTRYPOINT exec java $JAVA_OPTS -javaagent:"jmx_prometheus_javaagent-0.20.0.jar=8088:jmx_config.yaml" -jar teller-service-boot.jar