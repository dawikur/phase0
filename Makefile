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

b build: $(PRG)
.PHONY: b build

bt build_test:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test build
.PHONY: bt build_test

br build_release:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release build
.PHONY: br build_release

r resources: $(RESOURCES)
.PHONY: r resources

s simulate: build
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

sr simulate_release:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release simulate
.PHONY: st simulate_test

st simulate_test:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test simulate
.PHONY: st simulate_test

t test: $(RESOURCES)
	$(Q)echo " [ test ]"
	pytest
.PHONY: t test

ifneq ($(MODE),release)
w watch:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release watch
else
w watch: build
	$(Q)i=0; while ! gio mount -l | grep -q "mtp://091e_"; do
		set -- ⠋ ⠙ ⠸ ⠴ ⠦ ⠇
		shift $$((i % 6))
		printf "\r [ watch ] %s" "$$1"
		i=$$((i+1))
		sleep .1
	done; printf "\r\033[K"

	echo " [ watch ]"
	GVFS="/run/user/$$(id -u)/gvfs"
	MOUNT="$$(ls "$$GVFS" | grep 'mtp:host=' | head -n1)"
	TARGET="$$GVFS/$$MOUNT/Internal Storage/GARMIN/Apps"
	gio copy $(PRG) "$$TARGET/"
endif
.PHONY: w watch

c clean:
	$(Q)echo " [ clean ]"
	$(RM) -r bin $(BUILD_DIR) $(SRCS_GENERATED_DIR) $(RESOURCES) $(RESOURCES_GENERATED_DIR)
.PHONY: c clean

# ---- help ----

h help:
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
	echo "     b , build          build project"
	echo "     bt, build_test     build project w/ tests"
	echo "     br, build_release  build project in release"
	echo "     r , resources      generate resources"
	echo "     s , simulate       run simulator"
	echo "     st, simulate_test  run simulator w/ tests"
	echo "     w , watch          deploy release binary to watch"
	echo "     c , clean          remove build directory"
	echo "     h , help           print help message"
	echo ""
	echo " $${B}Arguments$${N}"
	echo "     NAME               (default: $(NAME))"
	echo "     DEVICE             (default: $(DEVICE))"
	echo "     MODE               (default: $(MODE))"
	echo "     V                  (default: $(V))"
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
