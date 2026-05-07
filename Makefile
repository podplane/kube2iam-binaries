.DEFAULT_GOAL := help

TAG ?=
DIST_DIR ?= dist

.PHONY: help build release clean check-tools

help:
	@echo "kube2iam-binaries"
	@echo
	@echo "Usage:"
	@echo "  make build TAG=0.15.0    Build and package kube2iam binaries from source"
	@echo "  make release TAG=0.15.0  Build, sign, and publish with GoReleaser"
	@echo "  make clean               Remove generated files"
	@echo
	@echo "Configuration:"
	@echo "  TAG=$(TAG)"
	@echo "  DIST_DIR=$(DIST_DIR)"

check-tools:
	@command -v git    >/dev/null 2>&1 || { echo "missing required tool: git" >&2; exit 1; }
	@command -v go     >/dev/null 2>&1 || { echo "missing required tool: go" >&2; exit 1; }
	@command -v goreleaser >/dev/null 2>&1 || { echo "missing required tool: goreleaser" >&2; exit 1; }
	@command -v jq     >/dev/null 2>&1 || { echo "missing required tool: jq" >&2; exit 1; }
	@command -v syft   >/dev/null 2>&1 || { echo "missing required tool: syft" >&2; exit 1; }

build: check-tools
	@[ -n "$(TAG)" ] || { echo "TAG is required, e.g. make build TAG=0.15.0" >&2; exit 1; }
	./scripts/build.sh "$(TAG)" "$(DIST_DIR)"

release: check-tools
	@[ -n "$(TAG)" ] || { echo "TAG is required, e.g. make release TAG=0.15.0" >&2; exit 1; }
	@command -v cosign >/dev/null 2>&1 || { echo "missing required tool: cosign" >&2; exit 1; }
	PUBLISH=true ./scripts/build.sh "$(TAG)" "$(DIST_DIR)"

clean:
	rm -rf dist tmp
