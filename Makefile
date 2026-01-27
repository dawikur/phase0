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

RESOURCES_DIR       := resources/
RESOURCES_BASE_DIR  := $(RESOURCES_DIR)base/
BUILD_SOURCE_DIR    := $(BUILD_DIR)source/

DRAWABLES_DEPS := scripts/generate_icon scripts/fonts_data.py scripts/fonts_model.py
DRAWABLES      := $(RESOURCES_BASE_DIR)drawables.xml
FONTS_DEPS     := scripts/generate_fonts scripts/fonts_data.py scripts/fonts_model.py
FONTS          := $(RESOURCES_BASE_DIR)fonts.xml

RESOURCES := $(DRAWABLES) $(FONTS)

PRG_DEPS := $(JUNGLE) $(SRCS) $(RSCS) $(RESOURCES)

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

$(FONTS): $(FONTS_DEPS)
	@$< --resources $(RESOURCES_DIR) --build $(BUILD_DIR)

$(DRAWABLES): $(DRAWABLES_DEPS)
	@$< --resources $(RESOURCES_DIR) --build $(BUILD_DIR)

$(BUILD_SOURCE_DIR):
	@mkdir -p $@

# ---- aliases ----

b: build
build_tag:
	@echo " [ build ]"
build: resources build_tag $(PRG)
.PHONY: b build build_tag

B: BUILD
BUILD_TAG:
	@echo " [ build w/ tests ]"
BUILD: resources BUILD_TAG $(PRG_TEST)
.PHONY: B BUILD BUILD_TAG

r: resources
resources_tag:
	@echo " [ resources ]"
resources: resources_tag $(RESOURCES)
.PHONY: r resources resources_tag

s: simulate
simulate: build
	@echo " [ simulate ]"
	$(CONNECTIQ)&
	SIM_PID=$$!
	sleep 1
	$(MONKEYDO) $(PRG) $(DEVICE)
	wait $$SIM_PID
.PHONY: s simulate

S: SIMULATE
SIMULATE: BUILD
	@echo " [ simulate w/ tests ]"
	$(CONNECTIQ)&
	SIM_PID=$$!
	sleep 1
	$(MONKEYDO) $(PRG_TEST) $(DEVICE) -t
	wait $$SIM_PID
.PHONY: S SIMULATE

c: clean
clean:
	@echo " [ clean ]"
	$(RM) -r bin $(BUILD_DIR) $(RESOURCES)
.PHONY: c clean

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
	echo "     r, resources       generate resources"
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
