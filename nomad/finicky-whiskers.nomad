job "finicky-whiskers" {
  datacenters = ["dc1"]
  type        = "service"

  group "finicky-whiskers-frontend" {
    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    service {
      name = "finicky-whiskers"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "redis"
              local_bind_port  = 6379
            }
          }
        }
      }
    }

    task "server" {
      driver = "exec"

      artifact {
        source      = "https://github.com/fermyon/spin/releases/download/v0.2.0/spin-v0.2.0-linux-amd64.tar.gz"
        destination = "local/bin"
      }

      artifact {
        source      = "git::https://github.com/fermyon/finicky-whiskers"
        destination = "local/repo"
      }

      env {
        RUST_LOG = "spin=debug"
      }

      config {
        command = "bash"
        args = [
          "-c",
          "local/bin/spin up --log-dir ${NOMAD_ALLOC_DIR}/logs --file local/repo/spin.toml --listen 0.0.0.0:8080 --env REDIS_ADDRESS=redis://localhost:6379"
        ]
      }
    }
  }

  group "finicky-whiskers-backend" {
    network {
      mode = "bridge"
      port "db" {
        to = 6379
      }
    }

    service {
      name = "finicky-whiskers-redis"
      port = "db"

      connect {
        sidecar_service {
          proxy {
          }
        }
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7"
      }
    }

    task "morsel" {
      driver = "exec"

      artifact {
        source      = "https://github.com/fermyon/spin/releases/download/v0.2.0/spin-v0.2.0-linux-amd64.tar.gz"
        destination = "local/bin"
      }

      artifact {
        source      = "git::https://github.com/fermyon/finicky-whiskers"
        destination = "local/repo"
      }

      env {
        RUST_LOG = "spin=debug"
      }

      config {
        command = "bash"
        args = [
          "-c",
          "local/bin/spin up --log-dir ${NOMAD_ALLOC_DIR}/logs --file local/repo/spin-morsel.toml --env REDIS_ADDRESS=redis://localhost:6379"
        ]
      }
    }
  }
}