SHELL := /bin/bash

all: ALL

.PHONY: all

MAKEFLAGS += --always-make

# read njobs from -j
NJOBS ?= $(subst -j,,$(filter -j%,$(MAKEFLAGS)))

##############################################################################
define TEMPLATE
# shellcheck disable=SC2034

#1. build with remote host
export REMOTE_HOST=
export REMOTE_WORKDIR=$${REMOTE_WORKDIR:-cmdlets}

#2. build with docker [default]
export DOCKER_IMAGE=$${DOCKER_IMAGE:-lcr.io/mtdcy/builder:ubuntu-latest}

# pass through envs
export UPKG_STRICT=0
export UPKG_MIRROR=$${UPKG_MIRROR:-http://pub.mtdcy.top}

# misc
export ULOGS=tty
export NJOBS=

# distcc
export DISTCC_VERBOSE=0
export DISTCC_HOSTS=""
export DISTCC_OPTS=

# install dest
export HOST=
export DEST=
endef

export TEMPLATE
cmdlets.env:
	@echo "$$TEMPLATE" > $@
	@echo "== Please edit $@ first, then"
	@echo "    source $@"
	@echo "    make prepare-host"
	@echo "OR  make prepare-docker"
	@echo "OR  make prepare-remote-homebrew"
	@echo "OR  make prepare-remote-debian"
	@echo ""
	@echo "    make zlib"

##############################################################################
# host environment variables => docker/remote
ENVS := NJOBS          \
		ULOGS          \
		UPKG_STRICT    \
		UPKG_MIRROR    \
		DISTCC_VERBOSE \
		DISTCC_HOSTS   \
		DISTCC_OPTS    \

OPTS := $(foreach v,$(ENVS),$(if $($(v)),$(v)=$($(v)),))

# internal variables
USER  	= $(shell id -u)
GROUP 	= $(shell id -g)
ARCH  	= $(shell gcc -dumpmachine | sed 's/[0-9\.]\+$$//;s/-alpine//')
WORKDIR = $(shell pwd)

##############################################################################
# Build Binaries & Libraries

vpath %.u libs

%: %.u
	@make runc CMD="bash ulib.sh build $@"

clean:
	@make runc CMD="rm -rf out/$(ARCH) logs/$(ARCH)"

distclean: clean
	@make runc CMD="rm -rf prebuilts/$(ARCH)"

shell:
	@make runc CMD="bash"

inspect:
	@make runc CMD="env && pwd && ls"

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

.PHONY: clean distclean shell prepare

##############################################################################
# host

BREW_PACKAGES 	= wget curl git                                    \
				  gnu-tar xz lzip unzip                            \
				  automake autoconf libtool pkg-config cmake meson \
				  nasm yasm bison flex                             \
				  luajit perl

DEB_PACKAGES 	= wget curl git                                    \
				  xz-utils lzip unzip                              \
				  build-essential                                  \
				  automake autoconf libtool pkg-config cmake meson \
				  nasm yasm bison flex                             \
				  luajit perl libhttp-daemon-perl                  \

prepare-host-homebrew:
	brew update
	brew install $(BREW_PACKAGES)

prepare-host-debian:
	sudo apt-get update -q
	sudo apt-get install -q -y $(DEB_PACKAGES)

ifneq (,$(shell which apt-get))
prepare-host: prepare-host-debian
else ifneq (,$(shell which brew))
prepare-host: prepare-host-homebrew
endif

runc-host:
	$(OPTS) $(CMD)

##############################################################################
# docker
# sync time between host and docker
#  => don't use /etc/timezone, as timedatectl won't update this file
TIMEZONE = $(shell realpath --relative-to /usr/share/zoneinfo /etc/localtime)

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

# pull always
DOCKER_ARGS += --pull=always -q

# name the docker container => nameless allow multiple instances
#DOCKER_ARGS += --name $(DOCKER_IMAGE)

# permissons
DOCKER_ARGS += --cap-add=SYS_ADMIN
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

# working dir
DOCKER_ARGS += -w $(WORKDIR)
DOCKER_ARGS += -v $(WORKDIR):$(WORKDIR):rw
#  => -w not always work, why?

# envs
DOCKER_ARGS += $(foreach v,$(ENVS),$(if $($(v)),-e $(v)=$($(v))))

ifeq ($(shell test -t 1),$(shell true))
DOCKER_RUNC = docker run --rm -it $(DOCKER_ARGS) $(DOCKER_IMAGE)
else
DOCKER_RUNC = docker run --rm -i $(DOCKER_ARGS) $(DOCKER_IMAGE)
endif

runc-docker:
	$(DOCKER_RUNC) 'cd $(WORKDIR); exec $(CMD)'

# TODO
runc-remote-docker:

##############################################################################
# remote:
REMOTE_WORKDIR ?= cmdlets

SSH_OPTS += -o BatchMode=yes
SSH_OPTS += -o StrictHostKeyChecking=no

# no distcc settings pass through to remote
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
	@bash ulib.sh ulogi "SHELL" "$(CMD) @ $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_RUNC) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && $(OPTS) $(CMD)"'
	@make pull-remote
	@bash ulib.sh ulogi "@END@" "Leaving $(REMOTE_HOST):$(REMOTE_WORKDIR)"

##############################################################################
# Install prebuilts @ Host
PREBUILTS = $(wildcard prebuilts/*)

# always update by checksum
install: $(PREBUILTS)
ifeq ($(HOST),)
	rsync -avc prebuilts/ $(DEST)/prebuilts/
else
	rsync -avcz prebuilts/ $(HOST):$(DEST)/prebuilts/
endif

.PHONY: install
.NOTPARALLEL: all

# vim:ft=make:ff=unix:fenc=utf-8:noet:sw=4:sts=0
