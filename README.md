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
  - `make -C docker build.base.dev` (dev base image)
  - Optionally: `make -C docker build.base.rel` or `make -C docker build.base.rc`
- Run
  - Start stack: `make -C docker up`
  - Stop stack: `make -C docker down`
  - Shell (dev app): `make -C docker shell.dev`
  - Shell (dev DB): `make -C docker shell.dev.db`

**Database Init (MSSQL, no Ruby)**
- Ruby-based init has been removed in favor of shell scripts.
- To initialize the MSSQL dev DB (create login/db/schemas) after the DB container is up:
  - `docker compose -f docker/deploy/docker-compose.yaml -f docker/deploy/mssql/docker-compose.yaml exec dev.db /bin/bash -lc "/home/mssql/scripts/setup-db.sh"`
  - Or if using the project’s compose context: `cd docker && ${CONTAINER_CLI:-docker} compose exec dev.db /bin/bash -lc "/home/mssql/scripts/setup-db.sh"`
- The script reads env from `docker/make.env/common.env` (+ `common.local.env`) via compose and uses `sqlcmd` inside the container.
- PostgreSQL deployments do not use Ruby here. If you want similar init for Postgres, we can add a shell/Python script that runs `psql` to create roles/db as needed.

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
  - Image pinned in config.
  - Set in `common.local.env`: `MSSQL_SA_PASSWORD`, `DEV_DB_USER`, `DEV_DB_PASSWORD`.
- PostgreSQL (`DEV_DB_TYPE=psql`)
  - Image pinned in config; adapter `postgres`.
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
