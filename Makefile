# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

# ---- arguments ----

NAME   ?= phase0
DEVICE ?= fr955
MODE   ?= debug
V      ?= 0

# ---- options ----

TAG.debug             :=
NAME_SUFFIX.debug     :=
FLAG_MONKEYC.debug    :=
FLAG_SIMULATE.debug   :=

TAG.test              := " \(test\)"
NAME_SUFFIX.test      := _test
FLAG_MONKEYC.test     := --unit-test
FLAG_SIMULATE.test    := -t

TAG.release           := " \(release\)"
NAME_SUFFIX.release   := _release
FLAG_MONKEYC.release  := --release
FLAG_SIMULATE.release :=

Q.0 := @
Q.1 :=
Q   := $(Q.$(V))

# ---- variables ----

SDK_DIR   := $(shell cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")
SDK_DIR   := $(patsubst %/,%,$(SDK_DIR))/
MONKEYC   := $(SDK_DIR)bin/monkeyc
MONKEYDO  := $(SDK_DIR)bin/monkeydo
CONNECTIQ := $(SDK_DIR)bin/connectiq

BUILD_DIR := build/
OUT       := $(NAME)-$(DEVICE)$(NAME_SUFFIX.$(MODE))
PRG       := $(BUILD_DIR)$(OUT).prg
JUNGLE    := monkey.jungle
SRCS      := $(shell find source -type f)
SRCS_DATA := $(shell find source/data -type f)
RSCS      := $(shell find resources -type f)

RESOURCES_DIR       := resources/
RESOURCES_BASE_DIR  := $(RESOURCES_DIR)base/
RESOURCES_BUILD_DIR := $(RESOURCES_DIR)build/

SOURCE_DIR       := source/
BUILD_SOURCE_DIR := $(BUILD_DIR)source/

SCRIPT_DEPS := scripts/args_parse.py \
               scripts/mc_document.py \
               scripts/utils.py \
               scripts/xml_document.py

ICON_DEPS      := scripts/generate_icon                      \
                  $(SCRIPT_DEPS)                             \
                  $(shell find data/fonts -type f)           \
                  $(shell find resources -name strings.xml)
ICON           := $(RESOURCES_BUILD_DIR)icon.xml
FONTS_DEPS     := scripts/generate_fonts                     \
                  $(SCRIPT_DEPS)                             \
                  $(shell find data/fonts -type f)
FONTS          := $(RESOURCES_BUILD_DIR)fonts.xml
SETTINGS_DEPS  := scripts/generate_settings                  \
                  $(SCRIPT_DEPS)                             \
                  $(shell find data/settings -type f)
SETTINGS       := $(RESOURCES_BUILD_DIR)settings.xml

RESOURCES := $(ICON) $(FONTS)

PRG_DEPS := $(JUNGLE) $(SRCS) $(RSCS) $(RESOURCES) $(SETTINGS)

# ---- settings ----

.DEFAULT_GOAL := build
.ONESHELL:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-print-directory

# ---- targets ----

$(PRG): $(PRG_DEPS)
	$(Q)$(MONKEYC) \
		--jungles $< \
		--device $(DEVICE) \
		--output $@ \
		--warn \
		--private-key $(HOME)/Documents/developer_key \
		$(FLAG_MONKEYC.$(MODE))

$(FONTS): $(FONTS_DEPS)
	$(Q)$< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(ICON): $(ICON_DEPS)
	$(Q)$< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(SETTINGS): $(SETTINGS_DEPS) $(SRCS_DATA)
	$(Q)$< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(BUILD_SOURCE_DIR):
	$(Q)mkdir -p $@

# ---- aliases ----

build_tag:
	$(Q)echo " [ build$(TAG.$(MODE)) ]"
b build: resources build_tag $(PRG)
.PHONY: b build build_tag

bt build_test:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test build
.PHONY: bt build_test

br build_release:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release build
.PHONY: br build_release

resources_tag:
	$(Q)echo " [ resources ]"
r resources: resources_tag $(RESOURCES)
.PHONY: r resources resources_tag

s simulate: build
	$(Q)echo " [ simulate$(TAG.$(MODE)) ]"
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

st simulate_test:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test simulate
.PHONY: st simulate_test

sr simulate_release:
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release simulate
.PHONY: sr simulate_release

t test:
	$(Q)echo " [ test ]"
	pytest
.PHONY: t test

c clean:
	$(Q)echo " [ clean ]"
	$(RM) -r bin $(BUILD_DIR) $(RESOURCES) $(RESOURCES_BUILD_DIR)
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
	echo "     br, build_release  build project release"
	echo "     r , resources      generate resources"
	echo "     s , simulate       run simulator"
	echo "     st, simulate_test  run simulator w/ tests"
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
