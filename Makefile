.PHONY: build run stop clean logs shell

IMAGE_NAME := secure-gateway
TAG := clawcloud
REGISTRY := nightlybible
FULL_IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(TAG)


# Build for amd64 only (always enforced)
build:
	docker build --platform linux/amd64 -t $(IMAGE_NAME):$(TAG) .

# Build and push to registry (amd64 only)
push:
	docker build --platform linux/amd64 -t $(FULL_IMAGE) .
	docker push $(FULL_IMAGE)


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

# Build without cache (amd64 only)
build-no-cache:
	docker build --platform linux/amd64 --no-cache -t $(IMAGE_NAME):$(TAG) .

# Help
help:
	@echo "Available targets:"
	@echo "  build           - Build image for amd64 only"
	@echo "  build-no-cache  - Build for amd64 only, no cache"
	@echo "  push            - Build and push image for amd64 only"
	@echo "  run             - Start with docker-compose"
	@echo "  stop            - Stop containers"
	@echo "  clean           - Clean up containers and images"
	@echo "  logs            - Show container logs"
	@echo "  shell           - Access container shell"
