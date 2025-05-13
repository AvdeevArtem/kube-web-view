# Kubernetes Web View

[![Build Status](https://travis-ci.com/hjacobs/kube-web-view.svg?branch=master)](https://travis-ci.com/hjacobs/kube-web-view)
[![Documentation Status](https://readthedocs.org/projects/kube-web-view/badge/?version=latest)](https://kube-web-view.readthedocs.io/en/latest/?badge=latest)
![Docker Pulls](https://img.shields.io/docker/pulls/hjacobs/kube-web-view.svg)
![License](https://img.shields.io/github/license/hjacobs/kube-web-view)
![CalVer](https://img.shields.io/badge/calver-YY.MM.MICRO-22bfda.svg)

Kubernetes Web View allows to list and view all Kubernetes resources (incl. CRDs) with permalink-friendly URLs in a plain-HTML frontend.
This tool was mainly developed to provide a web-version of `kubectl` for troubleshooting and supporting colleagues.
See the [Kubernetes Web View Documentation](https://kube-web-view.readthedocs.io/) for more information.

Goals:

* handling of any API resource: both core Kubernetes and CRDs
* permalink-friendly URL paths for giving links to colleagues (e.g. to help troubleshoot)
* option to work with multiple clusters
* allow listing different resource types on the same page (e.g. deployments and CRDs with same label)
* replicate some of the common `kubectl` features, e.g. `-l` (label selector) and `-L` (label columns)
* simple HTML, only add JavaScript where it adds value
* pluggable links, e.g. to link to other tools based on resource properties like labels (monitoring, reports, ..)
* optional: editing resources as YAML manifests (`kubectl edit`)

Non-goals:

* application management
* reporting/visualization
* fancy UI (JS/SPA)

## Quickstart

This will run Kubernetes Web View locally with your existing Kubeconfig:

```
docker run -it -p 8080:8080 -u $(id -u) -v $HOME/.kube:/.kube hjacobs/kube-web-view
```

Open http://localhost:8080/ in your browser to see the UI.

## Deploying into your cluster

This will deploy a single Pod with Kubernetes Web View into your cluster:

```
kubectl apply -f deploy/
kubectl port-forward service/kube-web-view 8080:80
```

Open http://localhost:8080/ in your browser to see the UI.


## Running tests

This requires Python 3.13 and [poetry](https://poetry.eustace.io/) and will run unit tests and end-to-end tests with [Kind](https://github.com/kubernetes-sigs/kind):

```
make test
```

It is also possible to run static and unit tests in docker env (`make test` is equal to `make poetry lint test.unit docker`)

```
docker run -it -v $PWD:/src -w /src python:3.13 /bin/bash -c "pip3 install poetry; make poetry lint test.unit"
make docker
```

The end-to-end (e2e) tests will bootstrap a new Kind cluster via [pytest-kind](https://pypi.org/project/pytest-kind/), you can keep the cluster and run Kubernetes Web View for development against it:

```
PYTEST_ADDOPTS=--keep-cluster make test
make run.kind
```


## Building the Docker image

```
make
```


## Developing Locally

To start the Python web server locally with the default kubeconfig (`~/.kube/config`):

```
make run
```
# Migration from Poetry to uv

This project has been migrated from Poetry to uv for dependency management. Here's what you need to know:

## Key Changes

1. **Dependency Management**: We now use `uv` instead of `poetry` for managing dependencies
2. **Lock File**: `uv.lock` replaces `poetry.lock`
3. **Dockerfile**: Updated to use `uv` for installing dependencies
4. **Makefile**: Updated with new commands for `uv`

## Development Setup

Install dependencies for development:

```bash
# Install uv if you don't have it yet
pip install uv

# Install the project in development mode with all dev dependencies
make setup.dev
```

## Running Tests

```bash
# Run all tests
make test

# Run only unit tests
make test.unit

# Run only e2e tests
make test.e2e
```

## Building Docker Image

```bash
# Build local Docker image
make docker.local

# Build multi-arch Docker image
make docker
```

## Adding New Dependencies

To add a new dependency:

```bash
# Add a runtime dependency
uv pip install package_name

# Add a development dependency
uv pip install --dev package_name

# Update the lock file
uv pip freeze > requirements.txt
uv pip compile pyproject.toml
```

## CI/CD Changes

The CI/CD pipeline has been updated to use `uv` instead of `poetry`. The main changes are:

1. Installing dependencies with `uv pip install` instead of `poetry install`
2. Using the new Dockerfile that uses `uv`

## Troubleshooting

If you encounter any issues with the migration, please:

1. Delete any existing virtual environments
2. Make sure you have the latest version of `uv` installed
3. Run `make setup.dev` to reinstall all dependencies
