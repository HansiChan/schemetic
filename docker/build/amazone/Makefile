MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO_ROOT := $(abspath $(MAKEFILE_DIR)/../../..)

include $(REPO_ROOT)/docker/make.env/common.env
include $(MAKEFILE_DIR)/build.env
include $(MAKEFILE_DIR)/../shared/build.env

include $(MAKEFILE_DIR)/../shared/build.mk

DOCKERFILE ?= $(MAKEFILE_DIR)/Dockerfile
BUILD_CONTEXT ?= $(REPO_ROOT)

# Build the app image using args from build.env
.PHONY: build.app
build.app:
	@set -e; \
	IMG="$(IMAGE)"; \
	if [ -z "$$IMG" ]; then \
	  if [ -n "${AMAZONE_IMAGE}" ] && [ "${AMAZONE_IMAGE##*:}" != "" ] && [ "${AMAZONE_IMAGE##*:}" != -* ]; then \
	    IMG="${AMAZONE_IMAGE}"; \
	  else \
	    IMG="${IMAGE_REPO_ROOT}/${PROJECT_NAME}_${APP_NAME}:amazone"; \
	  fi; \
	  echo "[info] IMAGE not provided; defaulting to $$IMG"; \
	fi; \
	BUILD_ENV_FILE="$(MAKEFILE_DIR)/build.env"; \
	if [ -f "$$BUILD_ENV_FILE" ]; then \
	  set -o allexport; . "$$BUILD_ENV_FILE"; set +o allexport; \
	fi; \
	PLATFORM_FLAG=""; \
	docker build $$PLATFORM_FLAG -f ${DOCKERFILE} \
	  --build-arg PYTHON_VERSION=$${PYTHON_VERSION} \
	  --build-arg UV_VERSION=$${UV_VERSION} \
	  --build-arg LABEL_SOURCE="$${LABEL_SOURCE}" \
	  --build-arg LABEL_BASE_NAME="$${LABEL_BASE_NAME}" \
	  -t $$IMG \
	  ${BUILD_CONTEXT}

.PHONY: push.app
push.app:
	@set -e; \
	IMG="$(IMAGE)"; \
	if [ -z "$$IMG" ]; then \
	  if [ -n "${AMAZONE_IMAGE}" ] && [ "${AMAZONE_IMAGE##*:}" != "" ] && [ "${AMAZONE_IMAGE##*:}" != -* ]; then \
	    IMG="${AMAZONE_IMAGE}"; \
	  else \
	    IMG="${IMAGE_REPO_ROOT}/${PROJECT_NAME}_${APP_NAME}:amazone"; \
	  fi; \
	  echo "[info] IMAGE not provided; defaulting to $$IMG"; \
	fi; \
	docker push $$IMG
