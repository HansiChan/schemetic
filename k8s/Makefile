include .env

# Path to the manifest relative to this directory
K8S_FILE ?= app.yaml
# Where to store the rendered manifest (ensures down matches up exactly)
K8S_OUT ?= .rendered.yaml

.PHONY: up down status render ns cm.up cm.down cm.render

# Apply with variable substitution using envsubst (from gettext)
up:
	@set -e; \
	$(MAKE) ns; \
	$(MAKE) cm.up; \
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
	kubectl get pods -n ${NAMESPACE:-flink} -o wide

# Ensure namespace exists
ns:
	kubectl get ns ${NAMESPACE:-flink} >/dev/null 2>&1 || kubectl create ns ${NAMESPACE:-flink}

# ---- ConfigMap for Python code ----
# Directory containing Python source files to mount into the Flink container
CODE_DIR ?= code
# Name of the ConfigMap used by app.yaml (mounted at /opt/flink/usrcode)
CODE_CM_NAME ?= pyflink-code

# Render the ConfigMap YAML from files (no apply)
cm.render:
	@set -e; \
	if [ ! -d "$(CODE_DIR)" ]; then echo "Missing $(CODE_DIR) directory"; exit 1; fi; \
	kubectl create configmap $(CODE_CM_NAME) \
	  --from-file=$(CODE_DIR) \
	  -n ${NAMESPACE:-flink} \
	  --dry-run=client -o yaml

# Create/Update the ConfigMap from local files
cm.up:
	@set -e; \
	if [ ! -d "$(CODE_DIR)" ]; then echo "Missing $(CODE_DIR) directory"; exit 1; fi; \
	kubectl create configmap $(CODE_CM_NAME) \
	  --from-file=$(CODE_DIR) \
	  -n ${NAMESPACE:-flink} \
	  --dry-run=client -o yaml | kubectl apply -f -

# Delete the ConfigMap
cm.down:
	@kubectl delete configmap $(CODE_CM_NAME) -n ${NAMESPACE:-flink} --ignore-not-found
