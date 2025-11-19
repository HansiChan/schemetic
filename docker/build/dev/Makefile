include ../../make.env/common.env
include build.env
include ../shared/build.env

include ../shared/build.mk

DOCKERFILE ?= Dockerfile

# Build the app image using args from build.env
.PHONY: build.app
build.app:
	@set -e; \
	IMG="$(IMAGE)"; \
	if [ -z "$$IMG" ]; then \
	  if [ -n "${DEV_IMAGE}" ] && [ "${DEV_IMAGE##*:}" != "" ] && [ "${DEV_IMAGE##*:}" != -* ]; then \
	    IMG="${DEV_IMAGE}"; \
	  else \
	    IMG="${IMAGE_REPO_ROOT}/${PROJECT_NAME}_${APP_NAME}:dev"; \
	  fi; \
	  echo "[info] IMAGE not provided; defaulting to $$IMG"; \
	fi; \
	LOCAL_FLINK_TMP="local-flink.tgz"; \
	cleanup() { rm -f "$$LOCAL_FLINK_TMP"; }; \
	trap cleanup EXIT; \
	if [ -n "${LOCAL_FLINK_TGZ}" ] && [ -f "${LOCAL_FLINK_TGZ}" ]; then \
	  echo "[info] Using local Flink tarball ${LOCAL_FLINK_TGZ}"; \
	  cp "${LOCAL_FLINK_TGZ}" "$$LOCAL_FLINK_TMP"; \
	else \
	  : > "$$LOCAL_FLINK_TMP"; \
	fi; \
	set -o allexport; [ -f build.env ] && . ./build.env; set +o allexport; \
	PLATFORM_FLAG=""; \
	docker build $$PLATFORM_FLAG -f ${DOCKERFILE} \
	  --build-arg PYTHON_VERSION=$${PYTHON_VERSION} \
	  --build-arg UV_VERSION=$${UV_VERSION} \
	  --build-arg LABEL_SOURCE="$${LABEL_SOURCE}" \
	  --build-arg LABEL_BASE_NAME="$${LABEL_BASE_NAME}" \
	  -t $$IMG \
	  ../../..

# Build the app image with Amazon Linux 2023 base
.PHONY: build.app.amazone
build.app.amazone:
	@set -e; \
	IMG="$(IMAGE)"; \
	if [ -z "$$IMG" ]; then \
	  if [ -n "${DEV_IMAGE}" ] && [ "${DEV_IMAGE##*:}" != "" ] && [ "${DEV_IMAGE##*:}" != -* ]; then \
	    BASE_IMG="${DEV_IMAGE%:*}"; \
	    IMG="$$BASE_IMG:amazone"; \
	  else \
	    IMG="${IMAGE_REPO_ROOT}/${PROJECT_NAME}_${APP_NAME}:amazone"; \
	  fi; \
	  echo "[info] IMAGE not provided; defaulting to $$IMG"; \
	fi; \
	LOCAL_FLINK_TMP="local-flink.tgz"; \
	cleanup() { rm -f "$$LOCAL_FLINK_TMP"; }; \
	trap cleanup EXIT; \
	if [ -n "${LOCAL_FLINK_TGZ}" ] && [ -f "${LOCAL_FLINK_TGZ}" ]; then \
	  echo "[info] Using local Flink tarball ${LOCAL_FLINK_TGZ}"; \
	  cp "${LOCAL_FLINK_TGZ}" "$$LOCAL_FLINK_TMP"; \
	else \
	  : > "$$LOCAL_FLINK_TMP"; \
	fi; \
	set -o allexport; [ -f build.env ] && . ./build.env; set +o allexport; \
	PLATFORM_FLAG=""; \
	docker build $$PLATFORM_FLAG -f Dockerfile.amazon2023 \
	  --build-arg PYTHON_VERSION=$${PYTHON_VERSION} \
	  --build-arg UV_VERSION=$${UV_VERSION} \
	  --build-arg LABEL_SOURCE="$${LABEL_SOURCE}" \
	  --build-arg LABEL_BASE_NAME="amazonlinux:2023" \
	  -t $$IMG \
	  ../../..

.PHONY: push.app
push.app:
	@set -e; \
	IMG="$(IMAGE)"; \
	if [ -z "$$IMG" ]; then \
	  if [ -n "${DEV_IMAGE}" ] && [ "${DEV_IMAGE##*:}" != "" ] && [ "${DEV_IMAGE##*:}" != -* ]; then \
	    IMG="${DEV_IMAGE}"; \
	  else \
	    IMG="${IMAGE_REPO_ROOT}/${PROJECT_NAME}_${APP_NAME}:dev"; \
	  fi; \
	  echo "[info] IMAGE not provided; defaulting to $$IMG"; \
	fi; \
	docker push $$IMG
