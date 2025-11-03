include ../../make.env/common.env
include build.env
include ../shared/build.env

include ../shared/build.mk

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
	set -o allexport; [ -f build.env ] && . ./build.env; set +o allexport; \
	docker build -f Dockerfile \
	  --build-arg PYTHON_VERSION=$${PYTHON_VERSION} \
	  --build-arg UV_VERSION=$${UV_VERSION} \
	  --build-arg LABEL_SOURCE="$${LABEL_SOURCE}" \
	  --build-arg LABEL_BASE_NAME="$${LABEL_BASE_NAME}" \
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
