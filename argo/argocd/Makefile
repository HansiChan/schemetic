ifndef KUBECTL_CMD
override KUBECTL_CMD = kubectl
endif

check_env_nulity:
	@[ -z "${env}" ] && \
	 { echo "Environment is NOT specified."; exit 1; } || \
	 exit 0

check_env_existence: check_env_nulity
	@[ -d "overlays/${env}" ] && exit 0 || \
	 { echo "Overlay for environment ${env} is NOT found."; exit 1; }

build: check_env_existence
	@kustomize build overlays/${env} > overlays/${env}/kustomization.lock.yaml && \
		echo "Kustomization file is built: overlays/${env}/kustomization.lock.yaml"

yaml_lint: check_env_existence
	@yamllint overlays/${env}

kube_lint: build
	@kube-linter lint overlays/${env}/kustomization.lock.yaml

lint: yaml_lint kube_lint

diff: lint
	@$(KUBECTL_CMD) diff -k overlays/${env}

apply: lint
	@$(KUBECTL_CMD) apply -k overlays/${env}

create_namespace: lint
	@${KUBECTL_CMD} apply -f overlays/${env}/namespace.yaml

clean: check_env_existence
	@[ -f "overlays/${env}/kustomization.lock.yaml" ] && \
		rm overlays/${env}/kustomization.lock.yaml && \
		echo "Kustomization file is deleted: overlays/dev/kustomization.lock.yaml" || \
		exit 0

.PHONY: check_env_nulity check_env_existence 
	build yaml_lint kube_lint lint 
	diff apply clean
