**Schematic**

Schematic provides a simple, Make-driven workflow to build and run containerized development environments with an optional dev database (MSSQL or PostgreSQL). It favors a single, readable env file and clear targets over heavy tooling.

**Highlights**
- Single env file: `docker/make.env/common.env`
- Local overrides: `docker/make.env/common.local.env` (gitignored)
- Switch DB type with `DEV_DB_TYPE` (`mssql` or `psql`)
- Make targets for build, compose, and utilities
- Project scaffolding from `project.tmpl`

**Prerequisites**
- Docker (or Podman with compatibility) installed and running
- GNU Make

**Quick Start**
- Configure
  - Copy `docker/make.env/common.local.env.example` to `docker/make.env/common.local.env`.
  - Edit `common.env` (defaults) and `common.local.env` (secrets/overrides):
    - Set `DEV_DB_TYPE=mssql` or `psql`.
    - Provide DB credentials in `common.local.env` only.
- Build images
  - Flink app image (SQL + Python baked into image):
    - Place Python entry at `src/app.py` and SQL at `src/sql/pipeline.sql`.
    - Plugins are auto-downloaded during build into `/opt/flink/flink-plugins` (from Maven Central by default). You can override versions/URLs with Docker build args in `docker/build/dev/Dockerfile` (e.g., `FLINK_VERSION`, `KAFKA_VERSION`, `LOG4J_VERSION`, `PAIMON_VERSION`, or explicit `PAIMON_*_JAR_URL`).
    - Optional Python deps: edit `docker/build/dev/requirements.txt`.
    - Build from repo root: `docker build -f docker/build/dev/Dockerfile -t <your-repo>/<name>:<tag> .`
  - Base images (optional for legacy flow):
    - `make -C docker build.base.dev`
    - Optionally: `make -C docker build.base.rel` or `make -C docker build.base.rc`
- Run (Compose, optional)
  - Start stack: `make -C docker up`
  - Stop stack: `make -C docker down`
  - Shell (dev app): `make -C docker shell.dev`
  - Shell (dev DB): `make -C docker shell.dev.db`

**App Image Build (build.env)**
- Configure
  - Edit `docker/build/dev/build.env` to set versions and labels:
    - `PYTHON_VERSION` — CPython version installed by `uv` (e.g., `3.11`).
    - `UV_VERSION` — `uv` installer version (e.g., `v0.4.20`).
    - `LABEL_SOURCE` — optional source identifier for image metadata.
    - `LABEL_BASE_NAME` — base image identifier (defaults to `flink:1.20.1-scala_2.12`).
- Layout
  - Python entry: `src/app.py`
  - SQL pipeline: `src/sql/pipeline.sql`
  - Plugins: downloaded at build time; see `docker/build/dev/Dockerfile` for overridable args
  - Python deps: `docker/build/dev/requirements.txt`
- Build and push
  - Build: `make -C docker/build/dev build.app`
    - Optional: set a custom tag with `IMAGE=<repo/name:tag>`
    - Default tag (if not provided): `${IMAGE_REPO_ROOT}/${PROJECT_NAME}_${APP_NAME}:dev`
  - Push: `make -C docker/build/dev push.app IMAGE=<repo/name:tag>`
  - The build target reads `build.env` and passes values as `--build-arg` automatically.

**Configuration**
- `docker/make.env/common.env`
  - User config to change most often:
    - `PROJECT_NAME`, `APP_NAME`, `IMAGE_REPO_ROOT`, `DEV_DB_TYPE`, `DEV_DB_NAME`, `DEV_DB_HOST`
  - Derived config (usually keep as-is):
    - `DEV_IMAGE_*` computed from names and `VERSION`
  - DB-specific blocks are enabled based on `DEV_DB_TYPE`.
- `docker/make.env/common.local.env`
  - Not committed; for secrets and machine-specific values.
  - Example at `docker/make.env/common.local.env.example`.

**Databases**
- MSSQL (`DEV_DB_TYPE=mssql`)
  - Set in `common.local.env`: `MSSQL_SA_PASSWORD`, `DEV_DB_USER`, `DEV_DB_PASSWORD`.
- PostgreSQL (`DEV_DB_TYPE=psql`)
  - Set in `common.local.env`: `POSTGRES_USER`, `POSTGRES_PASSWORD` (and optionally `DEV_DB_*`).

**Common Targets**
- Build
  - `make -C docker build.base.dev` | `build.base.rel` | `build.base.rc`
  - `make -C docker image.base.dev` | `push.base.dev` (and `rel|rc` variants)
- Compose
  - `make -C docker up` | `down` | `ps` | `logs`
  - `make -C docker up.dev` | `shell.dev` | `restart.dev` | `logs.dev`
  - `make -C docker up.dev.db` | `shell.dev.db` | `restart.dev.db` | `logs.dev.db`
- Utilities
  - `make -C docker prune` | `clean`

**Kubernetes Deployment**
- Prepare ConfigMaps/Secrets (run under `k8s/`):
  - CA certs: `make ca.up` — uses `k8s/ca/` (if present) or fallback file `k8s/minio-ca.crt`.
  - Bootstrap script: `make bootstrap.up` — packs `k8s/bootstrap/register-ca.sh` into ConfigMap `flink-bootstrap`.
  - Non-sensitive env: `make env.up` — from `k8s/env/config.env`.
  - Sensitive env: `make secret.up` — from `k8s/env/secret.env`.
- Apply FlinkDeployment:
  - `make up` — ensures namespace, applies above ConfigMap/Secret, renders `app.yaml`, and applies it.
- Where CA registration runs:
  - In the initContainer of the FlinkDeployment (`app.yaml`), which executes `/opt/bootstrap/register-ca.sh` to import CA into `/etc/ssl/truststore/cacerts`.

**Project Scaffolding**
- Create a new project from the template into a target directory:
  - MSSQL: `make create.project.mssql project=<name> app=<name> target=<path>`
  - PostgreSQL: `make create.project.psql project=<name> app=<name> target=<path>`
- The scaffolded project includes its own `docker/make.env/common.env` and supports `common.local.env` overrides.

**Repository Layout**
- `docker/`
  - `Makefile`, `Makefile.env`: Make entrypoints for builds and compose
  - `make.env/common.env`: Main configuration (this repo)
  - `make.env/common.local.env`: Local overrides (optional, gitignored)
  - `build/dev|rel|rc`: Image build contexts and Makefiles
  - `deploy/`: Compose specs and deploy-time envs
- `project.tmpl/`
  - Project template used by scaffolding, mirroring the structure above

**Troubleshooting**
- Ensure Docker daemon is running and your user can access it.
- If variables are missing, verify `common.env` exists and `common.local.env` is next to it.
- For database errors, confirm `DEV_DB_TYPE` and credentials in `common.local.env`.

**License**
- See `LICENSE` if present in your distribution.
