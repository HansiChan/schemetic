include .env

# Path to the manifest relative to this directory
K8S_FILE ?= app.yaml

.PHONY: up down status

up:
	kubectl apply -f $(K8S_FILE)

down:
	kubectl delete -f $(K8S_FILE) --ignore-not-found

status:
	kubectl get pods -n ${NAMESPACE:-flink} -o wide
