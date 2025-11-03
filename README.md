**Overview**
- Build a Flink application Docker image (Python + SQL included) and deploy it to Kubernetes via the Flink K8s Operator.
- The image bundles required JARs under `/opt/flink/flink-plugins` and launches your Python program using Flink’s Python driver.

**Prerequisites**
- Docker and GNU Make
- kubectl configured for your cluster
- Flink K8s Operator and CRDs installed in the cluster
- envsubst (from gettext) available in your shell
- Network access to Maven Central, Apache snapshots, and Cloudera repository

**Repository Layout**
- `src/`
  - `src/app.py` — Python entry program
  - `src/sql/pipeline.sql` — SQL used by the job
- `docker/build/dev/`
  - `Dockerfile` — builds the image and downloads JARs
  - `Makefile` — `build.app`, `push.app`
  - `requirements.txt` — Python dependencies
- `docker/make.env/`
  - `common.env` — shared defaults (used for default image tag composition)
  - `common.local.env` — local overrides (optional, gitignored)
- `k8s/`
  - `app.yaml` — FlinkDeployment template (rendered with `.env`)
  - `Makefile` — helper targets to set up namespace/configs and apply/delete
  - `env/config.env` — non‑sensitive env (ConfigMap)
  - `env/secret.env` — sensitive env (Secret)
  - `bootstrap/register-ca.sh` — init script to import a custom CA into a Java truststore

**Build The Image**
- Put your code in `src/app.py` and SQL in `src/sql/pipeline.sql`.
- Add Python libs to `docker/build/dev/requirements.txt`.
- Build with Make (recommended):
  - `make -C docker/build/dev build.app`
  - If `IMAGE` is not provided, the tag defaults to `${IMAGE_REPO_ROOT}/${PROJECT_NAME}_${APP_NAME}:dev` from `docker/make.env/common.env`.
  - Set a custom tag with `IMAGE=<repo/name:tag>`.
- Or build directly with Docker:
  - `docker build -f docker/build/dev/Dockerfile -t <repo/name:tag> .`

**What The Image Includes**
- Python runtime and your code under `/opt/flink/usrcode` and `/opt/flink/sql`.
- JARs downloaded into `/opt/flink/flink-plugins`:
  - Flink shaded Hadoop (from Cloudera): `flink-shaded-hadoop-3-3.1.1.7.2.9.0-173-9.0.jar`
  - Paimon snapshots (from ASF snapshots): `paimon-flink-1.20-1.4-<snapshot>.jar`, `paimon-s3-1.4-<snapshot>.jar`
  - Flink modules (from Maven Central): `flink-clients`, `flink-connector-datagen`, `flink-json`, `flink-kubernetes`, `flink-python`, `flink-s3-fs-hadoop`, `flink-scala_2.12`, `flink-sql-gateway`, `flink-table-api-java-uber`, `flink-table-planner-loader`, `flink-table-runtime`
  - Log4j stack (from Maven Central): `log4j-1.2-api`, `log4j-api`, `log4j-core`, `log4j-slf4j-impl`
- Versions/URLs can be overridden via Docker build args defined in the `Dockerfile` (e.g., `FLINK_VERSION`, `SCALA_BINARY`, `LOG4J_VERSION`, `PAIMON_*_JAR_URL`, `FLINK_SHADED_HADOOP_URL`).

**Configure Kubernetes**
- Create `k8s/.env` with values like:
  - `NAME=<app-name>`
  - `NAMESPACE=<namespace>` (e.g., `flink`)
  - `DEV_IMAGE=<your-image:tag>` (the image you built)
  - `FLINK_VERSION=1.20.1`
  - `FLINK_DEPLOY_MODE=application` (or `session`)
  - `SERVICE_ACCOUNT=default` (or another existing SA)
- Provide environment files:
  - `k8s/env/config.env` — non‑sensitive variables (ConfigMap)
  - `k8s/env/secret.env` — sensitive variables (Secret)
- Provide a CA certificate if your object store uses a custom CA:
  - Either place certs under `k8s/ca/` (directory) or a single file `k8s/minio-ca.crt`.
- Ensure a PVC named `flink-data` exists in the target namespace (or edit the volume in `k8s/app.yaml`).

**Deploy To Kubernetes**
- From the `k8s/` directory, run in order:
  - `make ns` — create namespace if missing
  - `make ca.up` — create/update CA ConfigMap (from `k8s/ca/` or `k8s/minio-ca.crt`)
  - `make bootstrap.up` — package `bootstrap/register-ca.sh` as ConfigMap
  - `make env.up` — create/update non‑sensitive env ConfigMap
  - `make secret.up` — create/update Secret
  - `make up` — render `app.yaml` with `.env` and apply the FlinkDeployment
- Check status and logs:
  - `make status` or `kubectl get pods -n $NAMESPACE`
  - `kubectl logs -n $NAMESPACE <jobmanager-pod>` (and taskmanagers as needed)

**How CA Registration Works**
- An initContainer runs `/opt/bootstrap/register-ca.sh` which:
  - Seeds a Java `cacerts` keystore (or creates one) at `/etc/ssl/truststore/cacerts`.
  - Imports your CA as alias `minio-ca`.
- The main container uses `JAVA_TOOL_OPTIONS` to trust that keystore for TLS.

**Customize**
- Edit `k8s/app.yaml` to change resources, parallelism, entry args, volumes, service account, or deployment mode.
- Adjust JAR coordinates or URLs with Docker build args if artifacts move or rotate.
- Swap or disable CA/truststore handling by updating the initContainer and related env/volumes in `k8s/app.yaml`.

**Tear Down**
- In `k8s/`: `make down` — deletes resources using the last rendered manifest (`k8s/.rendered.yaml`).

**Troubleshooting**
- Build failures while downloading JARs:
  - Verify network access to Maven Central, ASF snapshots, and Cloudera repository.
  - Override a specific URL with `--build-arg` if a snapshot rotated.
- `envsubst` not found when running `make up`:
  - Install gettext or pre‑render: `envsubst < k8s/app.yaml > k8s/.rendered.yaml` then `kubectl apply -f k8s/.rendered.yaml`.
- CA/truststore errors:
  - Ensure a valid cert is available in `k8s/ca/` or `k8s/minio-ca.crt`, or disable the initContainer and truststore wiring in `k8s/app.yaml`.

