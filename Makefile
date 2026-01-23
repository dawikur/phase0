# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

# ---- arguments ----

DEVICE ?= fr955
NAME   ?= phase0

# ---- variables ----

SDK_DIR   := $(shell cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")
SDK_DIR   := $(patsubst %/,%,$(SDK_DIR))/
MONKEYC   := $(SDK_DIR)bin/monkeyc
MONKEYDO  := $(SDK_DIR)bin/monkeydo
CONNECTIQ := $(SDK_DIR)bin/connectiq

BUILD_DIR := .build/
PRG       := $(BUILD_DIR)$(NAME).PRG
PRG_TEST  := $(BUILD_DIR)$(NAME)_test.PRG
JUNGLE    := monkey.jungle
SRCS      := $(shell find source -type f)
RSCS      := $(shell find resources -type f)

BUILD_RESOURCES_DIR := $(BUILD_DIR)resources/
BUILD_SOURCE_DIR    := $(BUILD_DIR)source/

FONTS_MC_DEPS  := scripts/generate_fonts_mc scripts/fonts_data.py scripts/fonts_model.py
FONTS_MC       := $(BUILD_SOURCE_DIR)fonts.mc
FONTS_XML_DEPS := scripts/generate_fonts_xml scripts/fonts_data.py scripts/fonts_model.py
FONTS_XML      := $(BUILD_RESOURCES_DIR)fonts.xml

ICON_DEPS := scripts/generate_icon scripts/fonts_data.py scripts/fonts_model.py
ICON      := $(BUILD_RESOURCES_DIR)icon.svg

PRG_DEPS   := $(JUNGLE) $(SRCS) $(RSCS) $(FONTS_MC) $(ICON)

# ---- settings ----

.DEFAULT_GOAL := build
.ONESHELL:
.DELETE_ON_ERROR:

# ---- targets ----

$(PRG): $(PRG_DEPS)
	@$(MONKEYC) \
		--jungles $< \
		--device $(DEVICE) \
		--output $@ \
		--warn \
		--private-key $(HOME)/Documents/developer_key

$(PRG_TEST): $(PRG_DEPS)
	@$(MONKEYC) \
		--jungles $< \
		--device $(DEVICE) \
		--output $@ \
		--warn \
		--private-key $(HOME)/Documents/developer_key \
		--unit-test

$(FONTS_MC): $(FONTS_MC_DEPS) $(BUILD_SOURCE_DIR)
	@$< --mc > $@

$(FONTS_XML): $(FONTS_XML_DEPS) $(BUILD_RESOURCES_DIR)
	@$< --xml > $@

$(ICON): $(ICON_DEPS) $(BUILD_RESOURCES_DIR)
	@$< > $@

$(BUILD_SOURCE_DIR):
	@mkdir -p $@

$(BUILD_RESOURCES_DIR):
	@mkdir -p $@

# ---- aliases ----

b: build
build_tag:
	@echo " [ build ]"
build: build_tag $(PRG)
.PHONY: build build_tag

B: BUILD
BUILD_TAG:
	@echo " [ build w/ tests ]"
BUILD: BUILD_TAG $(PRG_TEST)
.PHONY: BUILD BUILD_TAG

s: simulate
simulate: build
	@echo " [ simulate ]"
	$(CONNECTIQ)&
	SIM_PID=$$!
	sleep 1
	$(MONKEYDO) $(PRG) $(DEVICE)
	wait $$SIM_PID
.PHONY: simulate

S: SIMULATE
SIMULATE: BUILD
	@echo " [ simulate w/ tests ]"
	$(CONNECTIQ)&
	SIM_PID=$$!
	sleep 1
	$(MONKEYDO) $(PRG_TEST) $(DEVICE) -t
	wait $$SIM_PID
.PHONY: SIMULATE

c: clean
clean:
	@echo " [ clean ]"
	$(RM) -r bin $(BUILD_DIR)
.PHONY: clean

# ---- help ----

h: help
help:
	@echo " [ help ]"
	echo " Makefile for ConnectIQ project."
	echo ""
	echo " Usage: make [target] [arguments]"
	echo ""
	echo " Target:"
	echo "     b, build           build project"
	echo "     B, BUILD           build project w/ tests"
	echo "     f, fonts           generate fonts"
	echo "     s, simulate        run simulator"
	echo "     S, SIMULATE        run simulator w/ tests"
	echo "     c, clean           remove build directory"
	echo "     h, help            print help message"
	echo ""
	echo " Arguments:"
	echo "     DEVICE             (default: $(DEVICE))"
	echo "     NAME               (default: $(NAME))"
	echo ""
.PHONY: help
