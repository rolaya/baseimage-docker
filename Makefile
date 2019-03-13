ifndef BASE_IMAGE
	BASE_IMAGE = ubuntu:18.04
	NAME ?= phusion/baseimage
else ifdef NAME
else
	NAME = phusion/baseimage-$(subst :,-,${BASE_IMAGE})
endif
VERSION ?= 0.11


.PHONY: all build test tag_latest release ssh

all: build

build:
	docker build -t $(NAME):$(VERSION) --build-arg BASE_IMAGE=$(BASE_IMAGE) --rm image

test:
	env NAME=$(NAME) VERSION=$(VERSION) ./test/runner.sh

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag by creating an official GitHub release."

ssh: SSH_COMMAND?=
ssh: SSH_IDENTITY_FILE?=image/services/sshd/keys/insecure_key
ssh:
	chmod 600 ${SSH_IDENTITY_FILE}
	ID=$$(docker ps | grep -F "$(NAME):$(VERSION)" | awk '{ print $$1 }') && \
		if test "$$ID" = ""; then echo "Container is not running."; exit 1; fi && \
		IP=$$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $$ID) && \
		echo "SSHing into $$IP" && \
		ssh -v -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${SSH_IDENTITY_FILE} root@$$IP ${SSH_COMMAND}

test_release:
	echo test_release
	env

test_master:
	echo test_master
	env
