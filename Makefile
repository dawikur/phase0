# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

# ---- arguments ----

NAME   ?= phase0
DEVICE ?= fr955
MODE   ?= debug
V      ?= 0

# ---- options ----

NAME_SUFFIX.debug     :=
FLAG_MONKEYC.debug    :=
FLAG_SIMULATE.debug   :=

NAME_SUFFIX.test      := _test
FLAG_MONKEYC.test     := --unit-test
FLAG_SIMULATE.test    := -t

NAME_SUFFIX.release   := _release
FLAG_MONKEYC.release  := --release
FLAG_SIMULATE.release :=

Q.0 := @
Q.1 :=
Q   := $(Q.$(V))

# ---- variables ----

SDK_DIR   := $(shell cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")
SDK_DIR   := $(patsubst %/,%,$(SDK_DIR))/
MONKEYDO  := $(SDK_DIR)bin/monkeydo
CONNECTIQ := $(SDK_DIR)bin/connectiq

ifneq ($(MODE),release)
MONKEYC   := $(SDK_DIR)bin/monkeyc
else
MONKEYC   := node scripts/optimizedc.mjs
endif

BUILD_DIR := build/
OUT       := $(NAME)-$(DEVICE)$(NAME_SUFFIX.$(MODE))
PRG       := $(BUILD_DIR)$(OUT).prg
IQ        := $(BUILD_DIR)$(NAME).iq
JUNGLE    := monkey.jungle
SRCS      := $(shell find source -type f)
SRCS_DATA := $(shell find source/data -type f)
RSCS      := $(shell find resources -type f)

SRCS_GENERATED_DIR  := source/generated/

RESOURCES_DIR           := resources/
RESOURCES_BASE_DIR      := $(RESOURCES_DIR)base/
RESOURCES_GENERATED_DIR := $(RESOURCES_DIR)generated/

SOURCE_DIR       := source/

SCRIPT_DEPS    := $(shell find scripts/utils -type f)

ICON_DEPS      := scripts/generate_icon                      \
                  $(SCRIPT_DEPS)                             \
                  $(shell find data/fonts -type f)           \
                  $(shell find resources -name strings.xml)
ICON           := $(RESOURCES_GENERATED_DIR)icon.xml
FONTS_DEPS     := scripts/generate_fonts                     \
                  $(SCRIPT_DEPS)                             \
                  $(shell find data/fonts -type f)
FONTS          := $(RESOURCES_GENERATED_DIR)fonts.xml
SETTINGS_DEPS  := scripts/generate_settings                  \
                  $(SCRIPT_DEPS)                             \
                  $(shell find data/settings -type f)
SETTINGS       := $(RESOURCES_GENERATED_DIR)settings.xml

RESOURCES := $(ICON) $(FONTS) $(SETTINGS)

PRG_DEPS := $(JUNGLE) $(SRCS) $(RSCS) $(RESOURCES) $(SETTINGS)

# ---- settings ----

.DEFAULT_GOAL := build
.ONESHELL:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-print-directory

# ---- targets ----

$(PRG): $(PRG_DEPS)
	$(Q)echo " [ $(@F) ]"
	$(MONKEYC) \
		--jungles $< \
		--device $(DEVICE) \
		--output $@ \
		--warn \
		--private-key $(HOME)/Documents/developer_key \
		$(FLAG_MONKEYC.$(MODE))

$(IQ): $(PRG_DEPS)
	$(Q)echo " [ $(@F) ]"
	$(MONKEYC) \
		--jungles $< \
		--output $@ \
		--warn \
		--private-key $(HOME)/Documents/developer_key \
		$(FLAG_MONKEYC.$(MODE))

$(FONTS): $(FONTS_DEPS)
	$(Q)echo " [ $(@F) ]"
	$< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(ICON): $(ICON_DEPS)
	$(Q)echo " [ $(@F) ]"
	$< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(SETTINGS): $(SETTINGS_DEPS) $(SRCS_DATA)
	$(Q)echo " [ $(@F) ]"
	$< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(BUILD_SOURCE_DIR):
	$(Q)echo " [ $(@F) ]"
	mkdir -p $@

# ---- aliases ----

ifneq ($(MODE),release)
iq:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release iq
else
iq: $(IQ) # build iq project
endif
.PHONY: iq

b build: $(PRG) # build project for device
.PHONY: b build

bt build_test: # build project for device w/ tests
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test build
.PHONY: bt build_test

br build_release: # build project for device in release
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release build
.PHONY: br build_release

s simulate: build # run simulator
	$(Q)echo " [ simulate ] $(MODE)"
	$(CONNECTIQ)&
	SIM_PID=$$!
	sleep 3
	$(MONKEYDO) \
		$(PRG) \
		$(DEVICE) \
		-a $(BUILD_DIR)$(OUT)-settings.json:GARMIN/Settings/$(OUT)-settings.json \
		$(FLAG_SIMULATE.$(MODE))

	wait $$SIM_PID
.PHONY: s simulate

st simulate_test: # run simulator w/ tests
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test simulate
.PHONY: st simulate_test

sr simulate_release: # run simulator in release
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release simulate
.PHONY: st simulate_test

r resources: $(RESOURCES) # generate resources
.PHONY: r resources

t test: $(RESOURCES) # run test
	$(Q)echo " [ test ]"
	pytest
.PHONY: t test

ifneq ($(MODE),release)
w watch:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release watch
else
w watch: build # deploy release binary to watch
	$(Q)i=0; while ! gio mount -l | grep -q "mtp://091e_"; do
		set -- ⠋ ⠙ ⠸ ⢰ ⣠ ⣄ ⡆  ⠇
		shift $$((i % 8))
		printf "\r [ watch ] %s" "$$1"
		printf "\033[D"
		i=$$((i+1))
		sleep .1
	done; printf "\r\033[K"

	$(Q)echo " [ watch ]"
	GVFS="/run/user/$$(id -u)/gvfs"
	MOUNT="$$(ls "$$GVFS" | grep 'mtp:host=' | head -n1)"
	TARGET="$$GVFS/$$MOUNT/Internal Storage/GARMIN/Apps"
	gio copy $(PRG) "$$TARGET/"
endif
.PHONY: w watch

c clean: # remove build directory and files
	$(Q)echo " [ clean ]"
	$(RM) -r bin $(BUILD_DIR) $(SRCS_GENERATED_DIR) $(RESOURCES) $(RESOURCES_GENERATED_DIR)
.PHONY: c clean

# ---- help ----

h help: # print help message
	$(Q)echo " [ help ]"

	N="\033[m"
	B="\033[1m"
	I="\033[3m"
	U="\033[4m"

	echo ""
	echo " Makefile for ConnectIQ project."
	echo ""
	echo " $${B}Usage$${N}"
	echo "     $${B}make$${N} [$${U}target$${N}] [$${U}arguments$${N}]..."
	echo ""
	echo " $${B}Targets$${N}"
	awk -F'#' '\
	/^[[:alnum:]_-]+([[:space:]][[:alnum:]_-]+)*:.*#/ { \
		target_part = $$1; \
		sub(/:.*/, "", target_part); \
		split(target_part, a, " "); \
		short = a[1]; \
		long = ""; \
		for (j = 2; j <= length(a); j++) { \
			if (long != "") \
				long = long ", "; \
			long = long a[j]; \
		} \
		++n; \
		shorts[n] = short; \
		longs[n] = long; \
		desc[n] = $$2; \
		if (length(short) > max_short) max_short = length(short); \
		if (length(long) > max_long) max_long = length(long); \
		padding = 3 - max_short; \
	} \
	END { \
		for (i = 1; i <= n; i++) \
			printf "%" padding "s %" max_short "s %-" max_long "s %s\n", "", shorts[i], longs[i], desc[i]; \
	}' $(MAKEFILE_LIST)
	echo ""
	echo " $${B}Arguments$${N}"
	echo "     NAME              (default: $(NAME))"
	echo "     DEVICE            (default: $(DEVICE))"
	echo "     MODE              (default: $(MODE))"
	echo "     V                 (default: $(V))"
	echo ""
	echo " $${B}Devices$${N}"
	sed -n 's/.*iq:product id="\(.*\)"\/>/     \1/p' ./manifest.xml
	echo ""
	echo " $${B}Modes$${N}"
	echo "     debug"
	echo "     test"
	echo "     release"
	echo ""
.PHONY: help
