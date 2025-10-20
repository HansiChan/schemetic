include Makefile.env

build.base.dev:
	@$(MAKE) -C build/dev build

push.base.dev:
	@$(MAKE) -C build/dev push

shell.base.dev:
	@$(MAKE) -C build/dev shell

image.base.dev:
	@$(MAKE) -C build/dev image

build.base.rel:
	@$(MAKE) -C build/rel build

push.base.rel:
	@$(MAKE) -C build/rel push

shell.base.rel:
	@$(MAKE) -C build/rel shell

image.base.rel:
	@$(MAKE) -C build/rel image

build.base.rc:
	@$(MAKE) -C build/rc build

push.base.rc:
	@$(MAKE) -C build/rc push

shell.base.rc:
	@$(MAKE) -C build/rc shell

image.base.rc:
	@$(MAKE) -C build/rc image


prune:
	@${CONTAINER_CLI} image prune -f
clean: prune

image.dev:
	@${CONTAINER_CLI} images | grep ${DEV_IMAGE_REPO} | grep ${DEV_IMAGE_TAG} || \
		echo "Error! Dev image, ${DEV_IMAGE}, is NOT found. Probably need to build it:\n\n  make build.base.${DEV_IMAGE_RELEASE_TAG}"

up:
	@${CONTAINER_CLI} compose up -d
down:
	@${CONTAINER_CLI} compose down
ps:
	@${CONTAINER_CLI} compose ps -a
logs:
	@${CONTAINER_CLI} compose logs -f

up.dev:
	@${CONTAINER_CLI} compose up dev -d
shell.dev:
	@${CONTAINER_CLI} compose exec dev /bin/sh
restart.dev:
	@${CONTAINER_CLI} compose restart dev
logs.dev:
	@${CONTAINER_CLI} compose logs dev -f

up.dev.db:
	@${CONTAINER_CLI} compose up dev.db -d
shell.dev.db:
	@${CONTAINER_CLI} compose exec dev.db /bin/bash
restart.dev.db:
	@${CONTAINER_CLI} compose restart dev.db
logs.dev.db:
	@${CONTAINER_CLI} compose logs dev.db -f
