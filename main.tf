terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "default" {
  name = "default_network"
}

resource "docker_volume" "zookeeper_data" {
  name = "zookeeper_data"
}

resource "docker_volume" "kafka_data" {
  name = "kafka_data"
}

resource "docker_volume" "prometheus_data" {
  name = "prometheus_data"
}

resource "docker_volume" "minio_data" {
  name = "minio_data"
}

resource "docker_volume" "trino_data" {
  name = "trino_data"
}

resource "docker_container" "zookeeper" {
  image = "confluentinc/cp-zookeeper:latest"
  name  = "zookeeper"
  ports {
    internal = 2181
    external = 2181
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "ZOOKEEPER_CLIENT_PORT=2181",
    "ZOOKEEPER_TICK_TIME=2000"
  ]
  volumes {
    volume_name    = docker_volume.zookeeper_data.name
    container_path = "/var/lib/zookeeper"
  }
}

resource "docker_container" "kafka" {
  image = "confluentinc/cp-kafka:latest"
  name  = "kafka"
  ports {
    internal = 9092
    external = 9092
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "KAFKA_BROKER_ID=1",
    "KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181",
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092",
    "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1"
  ]
  volumes {
    volume_name    = docker_volume.kafka_data.name
    container_path = "/var/lib/kafka"
  }
}

resource "docker_container" "schema_registry" {
  image = "confluentinc/cp-schema-registry:latest"
  name  = "schema-registry"
  ports {
    internal = 8081
    external = 8082  # Changed external port to 8082 to avoid conflict
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS=PLAINTEXT://kafka:9092",
    "SCHEMA_REGISTRY_HOST_NAME=schema-registry"
  ]
}

resource "docker_container" "connect" {
  image = "confluentinc/cp-kafka-connect:latest"
  name  = "connect"
  ports {
    internal = 8083
    external = 8083
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "CONNECT_BOOTSTRAP_SERVERS=kafka:9092",
    "CONNECT_REST_ADVERTISED_HOST_NAME=connect",
    "CONNECT_GROUP_ID=compose-connect-group",
    "CONNECT_CONFIG_STORAGE_TOPIC=docker-connect-configs",
    "CONNECT_OFFSET_STORAGE_TOPIC=docker-connect-offsets",
    "CONNECT_STATUS_STORAGE_TOPIC=docker-connect-status",
    "CONNECT_KEY_CONVERTER=org.apache.kafka.connect.json.JsonConverter",
    "CONNECT_VALUE_CONVERTER=org.apache.kafka.connect.json.JsonConverter",
    "CONNECT_INTERNAL_KEY_CONVERTER=org.apache.kafka.connect.json.JsonConverter",
    "CONNECT_INTERNAL_VALUE_CONVERTER=org.apache.kafka.connect.json.JsonConverter",
    "CONNECT_REST_PORT=8083"
  ]
}

resource "docker_container" "debezium" {
  image = "debezium/connect:latest"
  name  = "debezium"
  ports {
    internal = 8084
    external = 8084
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "CONNECT_BOOTSTRAP_SERVERS=kafka:9092",
    "CONNECT_GROUP_ID=debezium",
    "CONNECT_CONFIG_STORAGE_TOPIC=debezium-connect-configs",
    "CONNECT_OFFSET_STORAGE_TOPIC=debezium-connect-offsets",
    "CONNECT_STATUS_STORAGE_TOPIC=debezium-connect-status",
    "CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE=false",
    "CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE=false"
  ]
}

resource "docker_container" "flink" {
  image = "flink:latest"
  name  = "flink"
  ports {
    internal = 8081
    external = 8085
  }
  networks_advanced {
    name = docker_network.default.name
  }
  command = ["bin/jobmanager.sh", "standalone-job"]
}

resource "docker_container" "nessie" {
  image = "projectnessie/nessie:latest"
  name  = "nessie"
  ports {
    internal = 19120
    external = 19120
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "QUARKUS_HTTP_PORT=19120"
  ]
}

resource "docker_container" "minio" {
  image = "minio/minio:latest"
  name  = "minio"
  ports {
    internal = 9000
    external = 9000
  }
  networks_advanced {
    name = docker_network.default.name
  }
  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data"
  }
  command = ["server", "/data"]
  env = [
    "MINIO_ACCESS_KEY=minioadmin",
    "MINIO_SECRET_KEY=minioadmin"
  ]
}

resource "docker_container" "prometheus" {
  image = "prom/prometheus:latest"
  name  = "prometheus"
  ports {
    internal = 9090
    external = 9090
  }
  networks_advanced {
    name = docker_network.default.name
  }
  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }
}

resource "docker_container" "grafana" {
  image = "grafana/grafana:latest"
  name  = "grafana"
  ports {
    internal = 3000
    external = 3000
  }
  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "superset" {
  image = "apache/superset:latest"
  name  = "superset"
  ports {
    internal = 8088
    external = 8088
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "SUPERSET_LOAD_EXAMPLES=yes",
    "SUPERSET_SECRET_KEY=your_secret_key",
    "SUPERSET_SQLALCHEMY_DATABASE_URI=sqlite:////home/superset/superset.db",
    "FLASK_APP=superset",
    "FLASK_ENV=development"
  ]
}

resource "docker_container" "jupyter" {
  image = "jupyter/base-notebook:latest"
  name  = "jupyter"
  ports {
    internal = 8888
    external = 8888
  }
  networks_advanced {
    name = docker_network.default.name
  }
  env = [
    "JUPYTER_ENABLE_LAB=yes"
  ]
}

resource "docker_container" "trino" {
  image = "trinodb/trino:latest"
  name  = "trino"
  ports {
    internal = 8080
    external = 8080
  }
  networks_advanced {
    name = docker_network.default.name
  }
  volumes {
    volume_name    = docker_volume.trino_data.name
    container_path = "/etc/catalog"
  }
  command = [
    "trino", 
    "--server", "0.0.0.0:8080", 
    "--catalog", "iceberg"
  ]
  provisioner "local-exec" {
    command = <<EOF
cat <<EOT > iceberg.properties
connector.name=iceberg
iceberg.catalog.type=hive
iceberg.catalog.warehouse=s3a://minio:9000/warehouse
hive.metastore.uri=thrift://nessie:9083
EOT
docker cp iceberg.properties ${self.name}:/etc/catalog/iceberg.properties
EOF
  }
}
