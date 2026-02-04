# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

# ---- arguments ----

DEVICE ?= fr955
MODE   ?= debug
NAME   ?= phase0
V      ?= 0

# ---- variables ----

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

SDK_DIR   := $(shell cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")
SDK_DIR   := $(patsubst %/,%,$(SDK_DIR))/
MONKEYC   := $(SDK_DIR)bin/monkeyc
MONKEYDO  := $(SDK_DIR)bin/monkeydo
CONNECTIQ := $(SDK_DIR)bin/connectiq

BUILD_DIR := build/
PRG       := $(BUILD_DIR)$(NAME)$(NAME_SUFFIX.$(MODE)).PRG
JUNGLE    := monkey.jungle
SRCS      := $(shell find source -type f)
RSCS      := $(shell find resources -type f)
STRINGS   := $(shell find resources -name strings.xml)

RESOURCES_DIR       := resources/
RESOURCES_BASE_DIR  := $(RESOURCES_DIR)base/
BUILD_SOURCE_DIR    := $(BUILD_DIR)source/

DRAWABLES_DEPS := scripts/generate_icon scripts/fonts_data.py scripts/fonts_model.py $(STRINGS)
DRAWABLES      := $(RESOURCES_BASE_DIR)drawables.xml
FONTS_DEPS     := scripts/generate_fonts scripts/fonts_data.py scripts/fonts_model.py
FONTS          := $(RESOURCES_BASE_DIR)fonts.xml

RESOURCES := $(DRAWABLES) $(FONTS)

PRG_DEPS := $(JUNGLE) $(SRCS) $(RSCS) $(RESOURCES)

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
	$(Q)$< --resources $(RESOURCES_DIR) --build $(BUILD_DIR)

$(DRAWABLES): $(DRAWABLES_DEPS)
	$(Q)$< --resources $(RESOURCES_DIR) --build $(BUILD_DIR)

$(BUILD_SOURCE_DIR):
	$(Q)mkdir -p $@

# ---- aliases ----

build_tag:
	$(Q)echo " [ build$(TAG.$(MODE)) ]"
b build: resources build_tag $(PRG)
.PHONY: b build build_tag

bt build_test:
	$(Q)$(MAKE) MODE=test build
.PHONY: bt build_test

br build_release:
	$(Q)$(MAKE) MODE=release build
.PHONY: br build_release

resources_tag:
	$(Q)echo " [ resources ]"
r resources: resources_tag $(RESOURCES)
.PHONY: r resources resources_tag

s simulate: build
	$(Q)echo " [ simulate$(TAG.$(MODE)) ]"
	$(CONNECTIQ)&
	SIM_PID=$$!
	sleep 1
	$(MONKEYDO) $(PRG) $(DEVICE) $(FLAG_SIMULATE.$(MODE))
	wait $$SIM_PID
.PHONY: s simulate

st simulate_test:
	$(Q)$(MAKE) MODE=test simulate
.PHONY: st simulate_test

c clean:
	$(Q)echo " [ clean ]"
	$(RM) -r bin $(BUILD_DIR) $(RESOURCES)
.PHONY: c clean

# ---- help ----

h help:
	$(Q)echo " [ help ]"
	echo " Makefile for ConnectIQ project."
	echo ""
	echo " Usage: make [target] [arguments]"
	echo ""
	echo " Target:"
	echo "     b , build          build project"
	echo "     bt, build_test     build project w/ tests"
	echo "     br, build_release  build project release"
	echo "     r , resources      generate resources"
	echo "     s , simulate       run simulator"
	echo "     st, simulate_test  run simulator w/ tests"
	echo "     c , clean          remove build directory"
	echo "     h , help           print help message"
	echo ""
	echo " Arguments:"
	echo "     DEVICE             (default: $(DEVICE))"
	echo "     MODE               (default: $(MODE))"
	echo "     NAME               (default: $(NAME))"
	echo "     V                  (default: $(V))"
	echo ""
.PHONY: help
