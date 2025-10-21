include .env

# Path to the manifest relative to this directory
K8S_FILE ?= app.yaml

.PHONY: up down status render

# Apply with variable substitution using envsubst (from gettext)
up:
	@set -e; \
	if command -v envsubst >/dev/null 2>&1; then \
	  set -o allexport; [ -f .env ] && . ./.env; \
	  envsubst < $(K8S_FILE) | kubectl apply -f -; \
	else \
	  echo "envsubst not found. Install gettext, or run: export vars; envsubst < $(K8S_FILE) | kubectl apply -f -"; \
	  exit 1; \
	fi

# Delete resources created from the rendered manifest
down:
	@set -e; \
	if command -v envsubst >/dev/null 2>&1; then \
	  set -o allexport; [ -f .env ] && . ./.env; \
	  envsubst < $(K8S_FILE) | kubectl delete -f - --ignore-not-found; \
	else \
	  echo "envsubst not found. Install gettext, or run: export vars; envsubst < $(K8S_FILE) | kubectl delete -f -"; \
	  exit 1; \
	fi

# Preview the rendered manifest (no apply)
render:
	@set -e; \
	if command -v envsubst >/dev/null 2>&1; then \
	  set -o allexport; [ -f .env ] && . ./.env; \
	  envsubst < $(K8S_FILE); \
	else \
	  echo "envsubst not found. Install gettext, or run: export vars; envsubst < $(K8S_FILE)"; \
	  exit 1; \
	fi

status:
	kubectl get pods -n ${NAMESPACE:-flink} -o wide
