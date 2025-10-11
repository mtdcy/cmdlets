.NOTPARALLEL:

SHELL := /bin/bash

all: shell

.PHONY: all

# DEFAULT ENVs

# read njobs from -j (bad: -jN not in MAKEFLAGS when job server is enabled)
#CL_NJOBS ?= $(patsubst -j%,%,$(filter -j%,$(MAKEFLAGS)))
CL_NJOBS 	?= $(shell nproc)
CL_MIRRORS 	?= https://mirrors.mtdcy.top
CL_LOGGING 	?= tty
CL_CCACHE 	?= 1

MAKEFLAGS 	+= --always-make

##############################################################################
.ONESHELL:

cmdlets.env:
	@echo "== Please edit $@ first, then"
	@echo "    source $@"
	@echo "    make prepare-host"
	@echo "OR  make prepare-docker"
	@echo "OR  make prepare-remote-homebrew"
	@echo "OR  make prepare-remote-debian"
	@echo ""
	@echo "    make zlib"
	cp .env $@

##############################################################################
# host environment variables => docker/remote
CL_ENVS :=  CL_FORCE 		\
			CL_NJOBS  		\
			CL_LOGGING     	\
			CL_STRICT    	\
			CL_MIRRORS    	\
			CL_CCACHE 	   	\

##############################################################################
# Build Binaries & Libraries
#${warning $(MAKEOVERRIDES)}
#${warning $(MAKEFLAGS)}

vpath %.u libs

%: %.u
	@$(MAKE) runc MAKEFLAGS= OPCODE="bash ulib.sh build $@"

clean:
	@$(MAKE) runc MAKEFLAGS= OPCODE="rm -rf out/$(ARCH) logs/$(ARCH)"

distclean: clean
	@$(MAKE) runc MAKEFLAGS= OPCODE="rm -rf prebuilts/$(ARCH)"

shell:
	@$(MAKE) runc MAKEFLAGS= OPCODE="bash"

inspect:
	@$(MAKE) runc MAKEFLAGS= OPCODE="env && pwd && ls"

ifneq ($(REMOTE_HOST),)
runc: runc-remote
else ifneq ($(BUILDER_NAME),)
runc: runc-host
else ifneq ($(DOCKER_IMAGE),)
runc: runc-docker
else
runc: runc-host
endif

ifneq ($(REMOTE_HOST),)
prepare: prepare-remote
else ifneq ($(BUILDER_NAME),)
prepare: prepare-host
else ifneq ($(DOCKER_IMAGE),)
prepare: prepare-docker
else
prepare: prepare-host
endif

mrproper:
	rm -rf out prebuilts logs packages registry

.PHONY: clean distclean shell prepare runc test mrproper

##############################################################################
# host

BREW_PACKAGES 	= coreutils grep gnu-sed findutils 				   \
				  bash wget curl git                     		   \
				  gnu-tar xz lzip unzip                            \
				  automake autoconf libtool pkg-config cmake meson \
				  nasm yasm bison flex gettext texinfo   		   \
				  luajit perl 									   \
				  ccache rustup golang

DEB_PACKAGES 	= wget curl git                                    \
				  xz-utils lzip unzip                              \
				  build-essential gettext                          \
				  automake autoconf libtool pkg-config cmake meson \
				  nasm yasm bison flex texinfo                     \
				  luajit perl libhttp-daemon-perl                  \
				  ccache musl-tools

APK_PACKAGES 	= wget curl git                                   \
				  grep sed gawk coreutils                         \
				  tar gzip xz lzip unzip zstd                     \
				  build-base gettext                              \
				  automake autoconf libtool pkgconfig cmake meson \
				  nasm yasm bison flex texinfo                    \
				  luajit perl perl-http-daemon                    \
				  ccache

prepare-host-homebrew:
	brew update
	brew install $(BREW_PACKAGES)
	$(MAKE) prepare-rust

prepare-host-debian:
	sudo apt-get update
	sudo apt-get install -y $(DEB_PACKAGES)
	which go || sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt-get update && sudo apt-get install golang-go
	$(MAKE) prepare-rust

prepare-host-alpine:
	sudo apk update
	sudo apk add --no-cache $(APK_PACKAGES)
	which go || sudo apk add --no-cache go

RUSTUP_INIT_OPTS := -y --no-modify-path --profile minimal --default-toolchain stable

prepare-rust:
	which rustup-init && rustup-init $(RUSTUP_INIT_OPTS) || true
	which rustup || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- $(RUSTUP_INIT_OPTS)
	which xcode-select || rustup target add $(shell uname -m)-unknown-linux-musl

ifneq (,$(shell which apt-get))
prepare-host: prepare-host-debian
else ifneq (,$(shell which brew))
prepare-host: prepare-host-homebrew
else ifneq (,$(shell which apk))
prepare-host: prepare-host-alpine
endif

HOST_ENV := $(foreach v,$(CL_ENVS),$(if $($(v)),$(v)=$($(v))))

runc-host:
	$(HOST_ENV) $(OPCODE)

##############################################################################
ifneq ($(DOCKER_IMAGE),)
# docker
# sync time between host and docker
#  => don't use /etc/timezone, as timedatectl won't update this file
TIMEZONE = $(shell realpath --relative-to /usr/share/zoneinfo /etc/localtime)

# internal variables
USER  	= $(shell id -u)
GROUP 	= $(shell id -g)
ARCH  	= $(shell gcc -dumpmachine | sed 's/[0-9\.]\+$$//;s/-alpine//')
WORKDIR = $(shell pwd)

prepare-docker-image:
	docker build                                  	\
		-t $(DOCKER_IMAGE)                        	\
		--build-arg LANG=${LANG}                  	\
		--build-arg TZ=$(TIMEZONE)                	\
		--build-arg MIRROR=http://mirrors.mtdcy.top \
		.

prepare-docker-image-alpine:
	docker build -f Dockerfile.alpine  			  	\
		-t $(DOCKER_IMAGE)                        	\
		--build-arg LANG=${LANG}                  	\
		--build-arg TZ=$(TIMEZONE)                	\
		--build-arg MIRROR=http://mirrors.mtdcy.top \
		.

# alias
prepare-docker: prepare-docker-image

DOCKER_PLATFORM ?= linux/amd64
DOCKER_ARGS += --platform $(DOCKER_PLATFORM)

# pull always
ifneq ($(shell dirname $(DOCKER_IMAGE)),.)
DOCKER_ARGS += --pull=always #--quiet
endif

# custom entrypoint
#DOCKER_ARGS += --entrypoint=''
#DOCKER_ARGS += -v ../Dockerfiles/builder/entrypoint.sh:/entrypoint.sh

# name the docker container => nameless allow multiple instances
#DOCKER_ARGS += --name $(DOCKER_IMAGE)

# permissons
#DOCKER_ARGS += --cap-add=SYS_ADMIN
#DOCKER_ARGS += --security-opt apparmor=unconfined

#DOCKER_ARGS += -u $(USER):$(GROUP)
DOCKER_ARGS += -e PUID=$(USER)
DOCKER_ARGS += -e PGID=$(GROUP)

#1. WSL bridge network has performance issue.
#2. Wine in docker takes looong time to start with host network.
DOCKER_NETWORK ?= host
DOCKER_ARGS += --network=$(DOCKER_NETWORK)

# mount
#DOCKER_ARGS += -v /etc/passwd:/etc/passwd:ro
#DOCKER_ARGS += -v /etc/group:/etc/group:ro
DOCKER_ARGS += -v /etc/localtime:/etc/localtime:ro

# working dir, su inside container with login shell will clear workdir
DOCKER_ARGS += -w $(WORKDIR)
DOCKER_ARGS += -v $(WORKDIR):$(WORKDIR):rw

# envs
DOCKER_ARGS += $(foreach v,$(CL_ENVS),$(if $($(v)),-e $(v)=$($(v))))

ifeq ($(shell test -t 0 && echo tty),tty)
DOCKER_RUNC = docker run --rm -it $(DOCKER_ARGS) $(DOCKER_IMAGE)
else
DOCKER_RUNC = docker run --rm -i $(DOCKER_ARGS) $(DOCKER_IMAGE)
endif

runc-docker:
	$(DOCKER_RUNC) $(OPCODE)

# TODO
runc-remote-docker:
endif

##############################################################################
ifneq ($(REMOTE_HOST),)
# remote:
REMOTE_WORKDIR ?= cmdlets

SSH_ENVS := $(foreach v,$(CL_ENVS),$(if $($(v)),$(v)=$($(v)),))

SSH_OPTS += -o BatchMode=yes
SSH_OPTS += -o StrictHostKeyChecking=no

REMOTE_RUNC := ssh $(REMOTE_HOST) $(SSH_OPTS) -tq TERM=xterm

prepare-remote-ssh:
	test -f ~/.ssh/id_rsa || ssh-keygen
	ssh-copy-id $(REMOTE_HOST)

prepare-remote:

# Please install 'Command Line Tools' first
#  => start a login shell to invoke brew prefixes
prepare-remote-homebrew: prepare-remote
	$(REMOTE_RUNC) '$$SHELL -li -c "brew install $(BREW_PACKAGES)"'

prepare-remote-debian: prepare-remote
	$(REMOTE_RUNC) 'sudo apt install -y $(DEB_PACKAGES)'

# TODO
prepare-remote-msys2:
	$(REMOTE_RUNC)

#1. rsync with ssh is the best way, no extra utils or services is needed.
#2. using default $SHELL instead of bash, as remote may set PATH for default login shell only.
#3. always request a TTY => https://community.hpe.com/t5/operating-system-linux/sshmake-session-quot-tput-no-value-for-term-and-no-t-specified/td-p/5255040
RSYNC_ARGS += -auv
RSYNC_ARGS += --exclude='.*'
RSYNC_ARGS += --exclude='out'

# contants: use '-acz' for remote without time sync.
REMOTE_SYNC := rsync -e 'ssh $(SSH_OPTS)' $(RSYNC_ARGS)
push-remote:
	@bash ulib.sh ulogi "@Push" "$(WORKDIR) => $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_SYNC) --exclude='prebuilts' --exclude='logs' --delete $(WORKDIR)/ $(REMOTE_HOST):$(REMOTE_WORKDIR)/

pull-remote:
	@bash ulib.sh ulogi "@Pull" "$(REMOTE_HOST):$(REMOTE_WORKDIR) => $(WORKDIR)"
	$(REMOTE_SYNC) $(REMOTE_HOST):$(REMOTE_WORKDIR)/ $(WORKDIR)/

# ToDo: enable AcceptEnv ?
runc-remote: push-remote
	@bash ulib.sh ulogi "SHELL" "$(OPCODE) @ $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_RUNC) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && $(SSH_ENVS) $(OPCODE)"'
	@make pull-remote
	@bash ulib.sh ulogi "@END@" "Leaving $(REMOTE_HOST):$(REMOTE_WORKDIR)"

endif

# vim:ft=make:ff=unix:fenc=utf-8:noet:sw=4:sts=0
