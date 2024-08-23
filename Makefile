VERSIONS := $(shell cat VERSIONS)
REVISION := b
NAME := nazman/pg_dump
PLATFORMS := linux/amd64,linux/arm64,linux/arm/v7

# Build images defined in the Docker Compose file
dc-build:
	docker-compose -f docker-compose-dev.yml build backup-12-16 backup-15-2

# Build and bring up the services in detached mode
dc-up: dc-build
	docker-compose -f docker-compose-dev.yml up -d backup-12-16 backup-15-2

# Show logs of the running services
dc-logs:
	docker-compose -f docker-compose-dev.yml logs -f backup-12-16 backup-15-2

# Open a bash shell in the backup-15-2 service
dc-bash:
	docker-compose -f docker-compose-dev.yml exec backup-15-2 bash

# Stop the running services
dc-stop:
	docker-compose -f docker-compose-dev.yml stop

# Log in to Docker
login:
	docker login

# Build Docker images for each version and platform
# Make sure you run command below before build:
# export DOCKER_CLI_EXPERIMENTAL=enabled
# docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
# docker buildx create --append --name mybuilder --driver docker-container --use
# docker buildx inspect mybuilder --bootstrap

version:
	for version in $(VERSIONS); do \
		docker buildx build --platform $(PLATFORMS) --build-arg POSTGRES_VERSION=$$version \
		-t $(NAME):$$version-$(REVISION) -t $(NAME):$$version --push .;\
	done
	docker buildx build --platform $(PLATFORMS) --build-arg POSTGRES_VERSION=$(lastword $(VERSIONS)) \
	-t $(NAME):latest --push .

# Push the built images to the Docker repository
push: version login
	for version in $(VERSIONS); do \
		docker image push $(NAME):$$version-$(REVISION); \
		docker image push $(NAME):$$version; \
	done
	docker image push $(NAME):latest