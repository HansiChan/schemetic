include .env

# Path to the manifest relative to this directory
K8S_FILE ?= app.yaml
# Where to store the rendered manifest (ensures down matches up exactly)
K8S_OUT ?= .rendered.yaml

.PHONY: up down status render ns

# Apply with variable substitution using envsubst (from gettext)
up:
	@set -e; \
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
