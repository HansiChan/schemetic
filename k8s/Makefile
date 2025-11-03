include .env

# Path to the manifest relative to this directory
K8S_FILE ?= app.yaml
# Where to store the rendered manifest (ensures down matches up exactly)
K8S_OUT ?= .rendered.yaml

.PHONY: up down status render ns ca.up ca.down ca.render bootstrap.up bootstrap.down bootstrap.render env.up env.down env.render secret.up secret.down secret.render

# Apply with variable substitution using envsubst (from gettext)

up:
	@set -e; \
	$(MAKE) ns; \
	$(MAKE) ca.up; \
	$(MAKE) bootstrap.up; \
	$(MAKE) env.up; \
	$(MAKE) secret.up; \
	if command -v envsubst >/dev/null 2>&1; then \
	  set -o allexport; [ -f .env ] && . ./.env; set +o allexport; \
	  envsubst < $(K8S_FILE) > $(K8S_OUT); \
	  kubectl apply -f $(K8S_OUT); \
	else \
	  echo "envsubst not found. Install gettext, or run: export vars; envsubst < $(K8S_FILE) > $(K8S_OUT) && kubectl apply -f $(K8S_OUT)"; \
	  exit 1; \
	fi

# Delete resources created from the saved rendered manifest
down:
	@set -e; \
	if [ -f $(K8S_OUT) ]; then \
	  kubectl delete -f $(K8S_OUT) --ignore-not-found; \
	else \
	  if command -v envsubst >/dev/null 2>&1; then \
	    set -o allexport; [ -f .env ] && . ./.env; set +o allexport; \
	    envsubst < $(K8S_FILE) | kubectl delete -f - --ignore-not-found; \
	  else \
	    echo "No $(K8S_OUT) and envsubst not found. Cannot reliably delete resources."; \
	    exit 1; \
	  fi; \
	fi

# Preview the rendered manifest (no apply)
render:
	@set -e; \
	if command -v envsubst >/dev/null 2>&1; then \
	  set -o allexport; [ -f .env ] && . ./.env; set +o allexport; \
	  envsubst < $(K8S_FILE); \
	else \
	  echo "envsubst not found. Install gettext, or run: export vars; envsubst < $(K8S_FILE)"; \
	  exit 1; \
	fi

status:
	kubectl get pods -n $${NAMESPACE:-flink} -o wide

# Ensure namespace exists
ns:
	kubectl get ns $${NAMESPACE:-flink} >/dev/null 2>&1 || kubectl create ns $${NAMESPACE:-flink}

# (Code ConfigMap no longer used — code is baked into image)

# ---- ConfigMap for CA certs ----
# Directory (or file) containing CA cert(s). If directory exists and not empty, use it;
# else fallback to file 'minio-ca.crt' in current directory.
CA_DIR ?= ca
CA_CM_NAME ?= cm-ca

ca.render:
	@set -e; \
	SRC_OPT=""; \
	if [ -d "$(CA_DIR)" ] && [ "$(shell ls -A $(CA_DIR) 2>/dev/null | wc -l)" -gt 0 ]; then \
	  SRC_OPT="--from-file=$(CA_DIR)"; \
	elif [ -f "minio-ca.crt" ]; then \
	  SRC_OPT="--from-file=minio-ca.crt"; \
	else \
	  echo "No CA sources found. Provide $(CA_DIR)/ or minio-ca.crt"; exit 1; \
	fi; \
	kubectl create configmap $(CA_CM_NAME) $$SRC_OPT -n $${NAMESPACE:-flink} --dry-run=client -o yaml

ca.up:
	@set -e; \
	SRC_OPT=""; \
	if [ -d "$(CA_DIR)" ] && [ "$(shell ls -A $(CA_DIR) 2>/dev/null | wc -l)" -gt 0 ]; then \
	  SRC_OPT="--from-file=$(CA_DIR)"; \
	elif [ -f "minio-ca.crt" ]; then \
	  SRC_OPT="--from-file=minio-ca.crt"; \
	else \
	  echo "No CA sources found. Provide $(CA_DIR)/ or minio-ca.crt"; exit 1; \
	fi; \
	kubectl create configmap $(CA_CM_NAME) $$SRC_OPT -n $${NAMESPACE:-flink} --dry-run=client -o yaml | kubectl apply -f -

ca.down:
	@kubectl delete configmap $(CA_CM_NAME) -n $${NAMESPACE:-flink} --ignore-not-found

# ---- ConfigMap for bootstrap script ----
BOOTSTRAP_DIR ?= bootstrap
BOOTSTRAP_CM_NAME ?= flink-bootstrap

bootstrap.render:
	@set -e; \
	if [ ! -f "$(BOOTSTRAP_DIR)/register-ca.sh" ]; then echo "Missing $(BOOTSTRAP_DIR)/register-ca.sh"; exit 1; fi; \
	kubectl create configmap $(BOOTSTRAP_CM_NAME) \
	  --from-file=register-ca.sh=$(BOOTSTRAP_DIR)/register-ca.sh \
	  -n $${NAMESPACE:-flink} \
	  --dry-run=client -o yaml

bootstrap.up:
	@set -e; \
	if [ ! -f "$(BOOTSTRAP_DIR)/register-ca.sh" ]; then echo "Missing $(BOOTSTRAP_DIR)/register-ca.sh"; exit 1; fi; \
	kubectl create configmap $(BOOTSTRAP_CM_NAME) \
	  --from-file=register-ca.sh=$(BOOTSTRAP_DIR)/register-ca.sh \
	  -n $${NAMESPACE:-flink} \
	  --dry-run=client -o yaml | kubectl apply -f -

bootstrap.down:
	@kubectl delete configmap $(BOOTSTRAP_CM_NAME) -n $${NAMESPACE:-flink} --ignore-not-found

# ---- ConfigMap for non-sensitive env ----
ENV_FILE ?= env/config.env
ENV_CM_NAME ?= flink-env

env.render:
	@set -e; \
	if [ ! -f "$(ENV_FILE)" ]; then echo "Missing $(ENV_FILE)"; exit 1; fi; \
	kubectl create configmap $(ENV_CM_NAME) \
	  --from-env-file=$(ENV_FILE) \
	  -n $${NAMESPACE:-flink} \
	  --dry-run=client -o yaml

env.up:
	@set -e; \
	if [ ! -f "$(ENV_FILE)" ]; then echo "Missing $(ENV_FILE)"; exit 1; fi; \
	kubectl create configmap $(ENV_CM_NAME) \
	  --from-env-file=$(ENV_FILE) \
	  -n $${NAMESPACE:-flink} \
	  --dry-run=client -o yaml | kubectl apply -f -

env.down:
	@kubectl delete configmap $(ENV_CM_NAME) -n $${NAMESPACE:-flink} --ignore-not-found

# ---- Secret for sensitive env ----
SECRET_FILE ?= env/secret.env
SECRET_NAME ?= flink-secret

secret.render:
	@set -e; \
	if [ ! -f "$(SECRET_FILE)" ]; then echo "Missing $(SECRET_FILE)"; exit 1; fi; \
	kubectl create secret generic $(SECRET_NAME) \
	  --from-env-file=$(SECRET_FILE) \
	  -n $${NAMESPACE:-flink} \
	  --dry-run=client -o yaml

secret.up:
	@set -e; \
	if [ ! -f "$(SECRET_FILE)" ]; then echo "Missing $(SECRET_FILE)"; exit 1; fi; \
	kubectl create secret generic $(SECRET_NAME) \
	  --from-env-file=$(SECRET_FILE) \
	  -n $${NAMESPACE:-flink} \
	  --dry-run=client -o yaml | kubectl apply -f -

secret.down:
	@kubectl delete secret generic $(SECRET_NAME) -n $${NAMESPACE:-flink} --ignore-not-found || \
	  kubectl delete secret $(SECRET_NAME) -n $${NAMESPACE:-flink} --ignore-not-found
