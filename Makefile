.PHONY: build run stop clean logs shell build-multi push-multi setup-buildx

IMAGE_NAME := secure-gateway
TAG := latest
REGISTRY := nightlybible
FULL_IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(TAG)

# Default build for local development
build:
	docker build -t  $(IMAGE_NAME):$(TAG) .

# Multi-architecture build (amd64 + arm64) - no load for multi-platform
build-multi: setup-buildx
	docker buildx build \
		 --platform linux/amd64,linux/arm64 \
		 --tag $(IMAGE_NAME):$(TAG) \
		 .

# Build and push multi-architecture image
push-multi: setup-buildx
	docker buildx build \
		 --platform linux/amd64,linux/arm64 \
		 --tag $(FULL_IMAGE) \
		 --push .

# Build only amd64
build-amd64: setup-buildx
	docker buildx build \
		 --platform linux/amd64 \
		 --tag $(IMAGE_NAME):$(TAG) \
		 --load .

# Setup buildx if not exists
setup-buildx:
	@if ! docker buildx ls | grep -q multiarch; then \
		 docker buildx create --name multiarch --use; \
	fi
	@docker buildx use multiarch

# Inspect multi-arch image
inspect:
	docker buildx imagetools inspect $(FULL_IMAGE)

# Local development
run:
	docker-compose up -d

stop:
	docker-compose down

clean:
	docker-compose down -v
logs:
	docker-compose logs -f

shell:
	docker-compose exec secure-gateway sh

# Tag and push to registry
tag:
	docker tag $(IMAGE_NAME):$(TAG) $(FULL_IMAGE)

push: tag
	docker push $(FULL_IMAGE)

# Complete build and publish workflow
publish: build-multi push-multi

# Clear buildx cache
clear-cache:
	docker buildx prune -f

# Build without cache
build-no-cache:
	docker build --no-cache -t $(IMAGE_NAME):$(TAG) .

# Multi-architecture build without cache
build-multi-no-cache: setup-buildx clear-cache
	docker buildx build \
		--no-cache \
		--platform linux/amd64,linux/arm64 \
		--tag $(IMAGE_NAME):$(TAG) \
		.

# Build and push without cache
push-multi-no-cache: setup-buildx clear-cache
	docker buildx build \
		--no-cache \
		--platform linux/amd64,linux/arm64 \
		--tag $(FULL_IMAGE) \
		--push .

# Help
help:
	@echo "Available targets:"
	@echo "  build        - Build image for current platform"
	@echo "  build-amd64  - Build for amd64 only"
	@echo "  build-multi  - Build for amd64 + arm64"
	@echo "  push-multi   - Build and push multi-arch image"
	@echo "  publish      - Complete build and publish workflow"
	@echo "  run          - Start with docker-compose"
	@echo "  stop         - Stop containers"
	@echo "  clean        - Clean up containers and images"
	@echo "  logs         - Show container logs"
	@echo "  shell        - Access container shell"
