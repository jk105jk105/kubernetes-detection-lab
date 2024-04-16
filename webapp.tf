provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_config_map" "mongo_config" {
  metadata {
    name      = "mongo-config"
    namespace = "nana-tf"
  }

  data = {
    mongo-url = "mongo-service"
  }
}

resource "kubernetes_secret" "mongo_secret" {
  metadata {
    name      = "mongo-secret"
    namespace = "nana-tf"
  }

  type = "Opaque"

  data = {
    mongo-user     = "bW9uZ291c2Vy"
    mongo-password = "bW9uZ29wYXNzd29yZA=="
  }
}

resource "kubernetes_deployment" "mongo_deployment" {
  metadata {
    name      = "mongo-deployment"
    namespace = "nana-tf"

    labels = {
      app = "mongo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mongo"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongo"
        }
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:5.0"

          port {
            container_port = 27017
          }

          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongo_secret.metadata[0].name
                key  = "mongo-user"
              }
            }
          }

          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongo_secret.metadata[0].name
                key  = "mongo-password"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mongo_service" {
  metadata {
    name      = "mongo-service"
    namespace = "nana-tf"
  }

  spec {
    selector = {
      app = "mongo"
    }

    port {
      protocol   = "TCP"
      port       = 27017
      target_port = 27017
    }
  }
}

resource "kubernetes_deployment" "webapp_deployment" {
  metadata {
    name      = "webapp-deployment"
    namespace = "nana-tf"

    labels = {
      app = "webapp"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "webapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "webapp"
        }
      }

      spec {
        container {
          name  = "webapp"
          image = "nanajanashia/k8s-demo-app:v1.0"

          port {
            container_port = 3000
          }

          env {
            name = "USER_NAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongo_secret.metadata[0].name
                key  = "mongo-user"
              }
            }
          }

          env {
            name = "USER_PWD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongo_secret.metadata[0].name
                key  = "mongo-password"
              }
            }
          }

          env {
            name = "DB_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.mongo_config.metadata[0].name
                key  = "mongo-url"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "webapp_service" {
  metadata {
    name      = "webapp-service"
    namespace = "nana-tf"
  }

  spec {
    type = "NodePort"

    selector = {
      app = "webapp"
    }

    port {
      protocol   = "TCP"
      port       = 3000
      target_port = 3000
      node_port  = 30111
    }
  }
}

