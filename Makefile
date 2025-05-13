.PHONY: clean test appjs docker push mock

IMAGE            ?= hjacobs/kube-web-view
GITDIFFHASH       = $(shell git diff | md5sum | cut -c 1-4)
VERSION          ?= $(shell git describe --tags --always --dirty=-dirty-$(GITDIFFHASH))
VERSIONPY         = $(shell echo $(VERSION) | cut -d- -f 1)
TAG              ?= $(VERSION)
TTYFLAGS          = $(shell test -t 0 && echo "-it")
OSNAME := $(shell uname | perl -ne 'print lc($$_)')
VENV             := .venv

default: docker

.PHONY: venv
venv:
	rm -rf $(VENV)
	uv venv $(VENV)

.PHONY: setup
setup: venv
	. $(VENV)/bin/activate && uv pip install -e .

.PHONY: setup.dev
setup.dev: venv
	. $(VENV)/bin/activate && uv pip install -e ".[dev]"

.PHONY: test
test: setup.dev lint test.unit test.e2e

.PHONY: lint
lint: venv
	. $(VENV)/bin/activate && pre-commit run --all-files

.PHONY: test.unit
test.unit: venv
	. $(VENV)/bin/activate && coverage run --source=kube_web -m pytest tests/unit
	. $(VENV)/bin/activate && coverage report

.PHONY: test.e2e
test.e2e: docker.local
	. $(VENV)/bin/activate && env TEST_IMAGE=$(IMAGE):$(TAG) \
		pytest -v -r=a \
			--log-cli-level info \
			--log-cli-format '%(asctime)s %(levelname)s %(message)s' \
			--cluster-name kube-web-view-e2e \
			tests/e2e

.PHONY: docker.local
docker.local:
	docker build -f Dockerfile.uv --build-arg "VERSION=$(VERSION)" -t "$(IMAGE):$(TAG)" .
	@echo 'Docker image $(IMAGE):$(TAG) can now be used.'

.PHONY: docker
docker:
	docker buildx create
	docker buildx build -f Dockerfile --rm --build-arg "VERSION=$(VERSION)" -t "$(IMAGE):$(TAG)" -t "$(IMAGE):latest" --platform linux/amd64,linux/arm64 .
	@echo 'Docker image $(IMAGE):$(TAG) multi-arch was build (cannot be used).'

push:
	docker buildx create
	docker buildx build -f Dockerfile --rm --build-arg "VERSION=$(VERSION)" -t "$(IMAGE):$(TAG)" -t "$(IMAGE):latest" --platform linux/amd64,linux/arm64 --push .
	@echo 'Docker image $(IMAGE):$(TAG) multi-arch can now be used.'

mock:
	docker run $(TTYFLAGS) -p 8080:8080 "$(IMAGE):$(TAG)" --mock

.PHONY: docs
docs: venv
	. $(VENV)/bin/activate && sphinx-build docs docs/_build

.PHONY: run
run: setup
	. $(VENV)/bin/activate && python -m kube_web --show-container-logs --debug "--object-links=ingresses=javascript:alert('{name}')" "--label-links=application=javascript:alert('Application label has value {label_value}')|eye|This is a link!" --preferred-api-versions=deployments=apps/v1

.PHONY: run.kind
run.kind: venv
	. $(VENV)/bin/activate && python -m kube_web --kubeconfig-path=.pytest-kind/kube-web-view-e2e/kubeconfig --debug --show-container-logs --search-default-resource-types=deployments,pods,configmaps --default-label-columns=pods=app "--default-hidden-columns=pods=Nominated Node" --exclude-namespaces=.*forbidden.* --resource-view-prerender-hook=kube_web.example_hooks.resource_view_prerender

.PHONY: mirror
mirror:
	git push --mirror git@github.com:hjacobs/kube-web-view.git

.PHONY: version
version:
	sed -i "s/^version = .*/version = \"${VERSIONPY}\"/" pyproject.toml
	sed -i "s/^version = .*/version = \"${VERSION}\"/" docs/conf.py
	sed -i "s/^__version__ = .*/__version__ = \"${VERSION}\"/" kube_web/__init__.py
	sed -i "s/v=[0-9A-Za-z._-]*/v=${VERSION}/g" kube_web/templates/base.html
