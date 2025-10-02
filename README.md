# AWS CloudShelf (CPSC‑465)

A hands‑on microservices project for California State University, Fullerton — pairing a Spring/Next.js bookstore demo with Docker, Terraform on AWS, and production‑style DevOps (observability, service discovery, config, and messaging).

> **At a glance**: Java/Kotlin (Spring Boot, WebFlux), Next.js (React + Tailwind), PostgreSQL, MongoDB, Kafka, Zipkin, Prometheus, Grafana, Docker Compose, Terraform (EC2 + Security Groups).

---

## Table of Contents

* [Project Goals](#project-goals)
* [Architecture Overview](#architecture-overview)
* [Repository Structure](#repository-structure)
* [Prerequisites](#prerequisites)
* [Local Quickstart (Docker Compose)](#local-quickstart-docker-compose)
* [Local Development (without Docker)](#local-development-without-docker)
* [Configuration & Environment Variables](#configuration--environment-variables)
* [AWS Deployment (Terraform → EC2)](#aws-deployment-terraform--ec2)
* [Useful URLs & Default Ports](#useful-urls--default-ports)
* [Troubleshooting](#troubleshooting)
* [Contributing](#contributing)
* [License & Credits](#license--credits)

---

## Project Goals

* Demonstrate a **microservices architecture** with service discovery, API gateway, externalized config, and polyglot persistence.
* Provide an **easy local run path** via Docker Compose profiles.
* Provide a **one‑click-ish AWS path** using Terraform to create an EC2 host, open required ports, and bootstrap the runtime.
* Include **observability**: traces (Zipkin) + metrics (Prometheus/Grafana).

## Architecture Overview

**Logical components** (monorepo):

* **API Gateway** (Spring Cloud Gateway) → single entrypoint to services
* **Discovery Server** (Eureka) → service registration/lookup
* **Config Server** (Spring Cloud Config) → centralized app config
* **Book Service** (Spring Boot + MongoDB + GraphQL)
* **Author Service** (Spring WebFlux + PostgreSQL)
* **Order Service** (Spring Boot + PostgreSQL)
* **Stock‑Check Service** (Kotlin + PostgreSQL)
* **Message Service** (Kafka producer/consumer)
* **Frontend** (Next.js + React + Tailwind)
* **Infra** (Kafka + Zookeeper, Postgres x2, MongoDB, Zipkin, Prometheus, Grafana)

> The services are intentionally lightweight to keep the focus on **integration patterns** rather than business complexity.

## Repository Structure

```
AWS-CloudShelf-CPSC-465/
├─ spring-microservices-bookstore-demo/   # Application monorepo (services + frontend + compose + k8s manifests)
├─ terraform/                             # EC2 + Security Groups + bootstrap installer
├─ install_resources.sh                   # Host bootstrap (packages, Docker, runtime setup)
└─ .gitignore
```

> **Tip:** Most local dev commands are run **inside** `spring-microservices-bookstore-demo/`.

## Prerequisites

* **Docker Desktop** (includes Docker Compose)
* **Java 17+** and **Maven** (if you want to build images locally)
* **Terraform** and an **AWS account** (for the EC2 path)

## Local Quickstart (Docker Compose)

1. **Build backend images** (uses JIB under the hood):

```bash
cd spring-microservices-bookstore-demo
mvn clean package -DskipTests
```

2. **Start infrastructure** (databases, Kafka, Zipkin, Prometheus, Grafana):

```bash
docker compose --profile infrastructure up -d
```

3. **Start discovery + config servers**:

```bash
docker compose --profile discovery-config up -d
```

4. **Start application services + frontend**:

```bash
docker compose --profile services up -d
```

5. Open the **Frontend**: [http://localhost:3000](http://localhost:3000)
   You can browse books/authors, place a demo order, and follow links to individual services.

> **Stop & clean**: `docker compose -p spring-microservices-bookstore-demo down` (from the same folder).

## Local Development (without Docker)

This mode is handy for debugging in IntelliJ/VS Code while the infra runs in containers.

* Keep **Docker Desktop running** and bring up infra only:

  ```bash
  docker compose --profile infrastructure up -d
  ```
* Start apps from your IDE **in order**: `discovery-server` → `config-server` → other services.
* Frontend can be run via `npm run dev` inside `frontend/` if you prefer hot‑reload during UI work.

## Configuration & Environment Variables

Create a `.env` (or export env vars) to keep config out of Compose files:

```dotenv
# Frontend (Next.js)
NEXT_PUBLIC_API_BASE=http://localhost:8080

# Gateway / CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Databases
POSTGRES_USER=admin
POSTGRES_PASSWORD=password
MONGO_INITDB_DATABASE=book-service

# Observability
PROMETHEUS_SCRAPE_INTERVAL=5s
GRAFANA_ADMIN_PASSWORD=admin
```

**How to wire it**:

* In Docker Compose: use `env_file: .env` or `environment:` blocks that read from the `.env`.
* In Terraform userdata or `install_resources.sh`, export the same vars before starting services on the host.

> **Why `.env`?** Avoids hardcoding values like `CORS_ALLOWED_ORIGINS=http://<EC2_PUBLIC_IP>:3000` into YAML. Just keep the IP/URLs in `.env` (checked‑in or, better, stored in a private location).

## AWS Deployment (Terraform → EC2)

This creates one EC2 host, security groups, and bootstraps Docker + the app via `install_resources.sh`.

### 1) Prepare AWS & Terraform

* Configure AWS credentials (`aws configure`) with a profile that has EC2 permissions.
* Have an SSH keypair available locally.
* Ensure `install_resources.sh` is **executable** and uses **LF** line endings on macOS/Linux:

  ```bash
  chmod +x install_resources.sh
  ```

### 2) Review/Set TF variables

Common patterns (names may differ in your `variables.tf`):

* `ssh_private_key_path` → path to your **private** key used by provisioners (e.g., `~/.ssh/id_rsa`).
* `allowed_ingress_cidrs` → IP ranges allowed to reach your instance (lock this down!).
* `open_ports` → include at least **22**, **3000** (Frontend), **3001** (Grafana); optionally **80/443** if you add Nginx/ALB.

### 3) Apply

```bash
cd terraform
terraform init -upgrade
terraform validate
terraform apply -auto-approve
```

When finished, note the **EC2 Public IP / DNS** from Terraform outputs.

### 4) Connect & test

* Frontend: `http://<EC2_PUBLIC_IP>:3000`
* Grafana: `http://<EC2_PUBLIC_IP>:3001` (default admin/admin unless changed)
* If you’ve placed CORS origins into `.env`, make sure they include your EC2 URL.

### 5) Destroy (optional)

```bash
terraform destroy -auto-approve
```

## Useful URLs & Default Ports

* **Frontend (Next.js)** — `http://localhost:3000`
* **Grafana** — `http://localhost:3001`
* **Prometheus** — `http://localhost:9090`
* **Zipkin** — `http://localhost:9411`
* **Eureka (Discovery)** — `http://localhost:8761`
* **Config Server** — `http://localhost:8888`
* **Kafka broker** — `localhost:9092`
* **MongoDB** — `localhost:27017`
* **PostgreSQL (order‑service)** — `localhost:5432`
* **PostgreSQL (author‑service)** — `localhost:5433`

> Exact ports come from the application’s Docker Compose; if you change mappings there, update them here too.

## Troubleshooting

**Docker daemon not running**
`error during connect: this error may indicate that the docker daemon is not running…` → Start Docker Desktop, then rebuild images.

**Compose build warnings about credentials**
Log in to Docker Hub from Docker Desktop to avoid credential helper warnings.

**Terraform file provisioner path error**
Double‑check `ssh_private_key_path` and that `install_resources.sh` exists at the path referenced in `main.tf`. On macOS, prefer `~/.ssh/<key>` with `chmod 600`.

**Ports inaccessible on EC2**
Verify Security Group rules include the ports you need (22/3000/3001/etc.) for the client IP ranges you expect.

**CORS errors in browser**
Update `CORS_ALLOWED_ORIGINS` in `.env` to include your browser’s origin, then restart the gateway/frontend.

**M1/M2/M3/M4 Macs**
If any image lacks `linux/arm64` support, add `--platform=linux/amd64` to the build/run or use Kubernetes + multi‑arch builds.

## Contributing

* Use conventional commit messages (e.g., `feat:`, `fix:`, `docs:`).
* Open a PR with a short demo (screenshots or curl commands) that shows the change working.

## License & Credits

* The microservices demo is inspired by the excellent **Spring Microservices Bookstore** example by Chris Bailey.
* This repository is for academic use (CPSC‑465) and personal learning.

---

### Appendix: Helpful Commands

```bash
# See running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Tail logs for a service
docker compose logs -f api-gateway

# Rebuild a single service image with JIB
mvn -pl order-service -am clean package -DskipTests

# Wipe compose stack (including volumes)
docker compose down -v
```
