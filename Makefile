#!/bin/bash

ARCH ?= $(shell arch)

.PHONY: pipy
pipy:
	@if [ ! -f /usr/local/bin/pipy ]; then wget https://github.com/flomesh-io/pipy/releases/download/0.90.2-13/pipy-0.90.2-13-generic_linux-$(ARCH).tar.gz && tar zxf pipy-0.90.2-13-generic_linux-$(ARCH).tar.gz && cp usr/local/bin/pipy /usr/local/bin && rm -rf pipy-0.90.2-13-generic_linux-$(ARCH).tar.gz usr; fi

.PHONY: install-latest-docker
install-latest-docker:
	for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove ${pkg}; done
	sudo apt -y update
	sudo apt -y install ca-certificates curl gnupg
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	echo "deb [arch=${shell dpkg --print-architecture} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${shell . /etc/os-release && echo $${VERSION_CODENAME}} stable"  | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt -y update
	sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

.PHONY: install-test-depends
install-test-depends:
	sudo apt -y install bridge-utils net-tools iproute2 socat

.PHONY: depends
depends: install-latest-docker install-test-depends pipy

.PHONY: docker-fsmxlb
docker-fsmxlb:
	docker pull cybwan/fsm-xlb:latest
	docker run -u root --cap-add SYS_ADMIN --restart unless-stopped --privileged -dit -v /dev/log:/dev/log --name fsmxlb cybwan/fsm-xlb:latest

.PHONY: simple-topo
simple-topo:
	scripts/simple-test-topology.sh

.PHONY: simple-clean
simple-clean:
	ip netns delete ep1 >> /dev/null 2>&1 || true
	ip netns delete ep2 >> /dev/null 2>&1 || true
	ip netns delete ep3 >> /dev/null 2>&1 || true
	ip netns delete h1 >> /dev/null 2>&1 || true
	umount /var/run/netns/fsmxlb >> /dev/null 2>&1 || true
	rm -rf /var/run/netns/fsmxlb >> /dev/null 2>&1 || true
	docker stop fsmxlb >> /dev/null 2>&1 || true
	docker rm fsmxlb >> /dev/null 2>&1 || true

.PHONY: simple-test
simple-test:
	@ip netns exec h1 curl 20.20.20.1:8080
	@ip netns exec h1 curl 20.20.20.1:8080
	@ip netns exec h1 curl 20.20.20.1:8080