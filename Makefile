# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

# ---- arguments ----

# binary name
NAME        ?= phase0
# target device
DEVICE      ?= fr955
# build mode
MODE        ?= debug
# show commands
V           ?= 0
# developer key path
PRIVATE_KEY ?= $(HOME)/Documents/developer_key

# ---- options ----

# development build
NAME_SUFFIX.debug     :=
FLAG_MONKEYC.debug    :=
FLAG_SIMULATE.debug   :=

# unit-test build
NAME_SUFFIX.test      := _test
FLAG_MONKEYC.test     := --unit-test
FLAG_SIMULATE.test    := -t

# build with an optimized output name
NAME_SUFFIX.optimized   := _optimized
FLAG_MONKEYC.optimized  :=
FLAG_SIMULATE.optimized :=

# signed release build
NAME_SUFFIX.release   := _release
FLAG_MONKEYC.release  := --release
FLAG_SIMULATE.release :=

NAME_SUFFIX   := $(NAME_SUFFIX.$(MODE))
FLAG_MONKEYC  := $(FLAG_MONKEYC.$(MODE))
FLAG_SIMULATE := $(FLAG_SIMULATE.$(MODE))

Q.0 := @
Q.1 :=
Q   := $(Q.$(V))

HELP_DESCRIPTION_COLUMN := 26

# ---- variables ----

SDK_TARGETS := b build build_optimized bo build_release br s simulate st simulate_test so simulate_optimized sr simulate_release w watch

ifneq ($(strip $(MAKECMDGOALS)),)
ifneq ($(filter $(SDK_TARGETS),$(MAKECMDGOALS)),)
SDK_DIR := $(shell cat "$(HOME)/.Garmin/ConnectIQ/current-sdk.cfg")
endif
else
SDK_DIR := $(shell cat "$(HOME)/.Garmin/ConnectIQ/current-sdk.cfg")
endif

SDK_DIR   := $(patsubst %/,%,$(SDK_DIR))/
MONKEYDO  := $(SDK_DIR)bin/monkeydo
CONNECTIQ := $(SDK_DIR)bin/connectiq

ifneq ($(MODE),release)
MONKEYC   := $(SDK_DIR)bin/monkeyc
else
MONKEYC   := node scripts/optimizedc.mjs
endif

BUILD_DIR := build/
DOCS_DIR  := docs/
DOCS_OUTPUT_DIR := $(BUILD_DIR)docs/
DOCS_EXPORT_STAMP := $(BUILD_DIR).docs.stamp
OUT       := $(NAME)-$(DEVICE)$(NAME_SUFFIX)
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

SOURCE_DIR         := source/

SCRIPT_DEPS        := $(shell find scripts/utils -type f)

ICON_DEPS          := scripts/generate_icon                      \
                      $(SCRIPT_DEPS)                             \
                      $(shell find data/fonts -type f)           \
                      $(shell find resources -name strings.xml)
ICON               := $(RESOURCES_GENERATED_DIR)icon.xml
FONTS_DEPS         := scripts/generate_fonts                     \
                      $(SCRIPT_DEPS)                             \
                      $(shell find data/fonts -type f)           \
                      $(shell find resources -name strings.xml)
FONTS              := $(RESOURCES_GENERATED_DIR)fonts.xml
SETTINGS_DEPS      := scripts/generate_settings                  \
                      $(SCRIPT_DEPS)                             \
                      $(shell find data/fonts -type f)           \
                      $(shell find data/settings -type f)
SETTINGS           := $(RESOURCES_GENERATED_DIR)settings.xml
DOCS_SETTINGS_DEPS := scripts/generate_docs_settings             \
                      scripts/utils/docs_settings.py             \
                      $(SETTINGS)                                \
                      $(shell find resources -name strings.xml)
DOCS_SETTINGS       := $(DOCS_DIR)settings-data.js
DOCS_ICON           := $(DOCS_DIR)assets/icon.svg
DEVICE_OVERLAY_SRC  := $(DOCS_DIR)assets/fr955.png
DOCS_DEVICE_OVERLAY_LIGHT := $(DOCS_DIR)assets/fr955-light.png
DOCS_DEVICE_OVERLAY_DARK  := $(DOCS_DIR)assets/fr955-dark.png
DOCS_DEVICE_OVERLAYS := $(DOCS_DEVICE_OVERLAY_LIGHT) $(DOCS_DEVICE_OVERLAY_DARK)

RESOURCES := $(ICON) $(FONTS) $(SETTINGS)

PRG_DEPS := $(JUNGLE) $(SRCS) $(RSCS) $(RESOURCES) $(SETTINGS)

# ---- settings ----

.DEFAULT_GOAL := build
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -e -o pipefail -c
SHELL := /bin/bash

MAKEFLAGS += --no-print-directory

# ---- targets ----

FORCE:
.PHONY: FORCE

$(PRG): $(PRG_DEPS)
	$(Q)echo " [ $(@F) ]"
	$(MONKEYC) \
		--jungles $< \
		--device $(DEVICE) \
		--output $@ \
		--warn \
		--private-key $(PRIVATE_KEY) \
		$(FLAG_MONKEYC)

$(IQ): $(PRG_DEPS)
	$(Q)echo " [ $(@F) ]"
	$(MONKEYC) \
		--jungles $< \
		--output $@ \
		--warn \
		--private-key $(PRIVATE_KEY) \
		$(FLAG_MONKEYC)

$(FONTS): $(FONTS_DEPS)
	$(Q)echo " [ $(@F) ]"
	PYTHONPATH=. $< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(ICON): $(ICON_DEPS)
	$(Q)echo " [ $(@F) ]"
	PYTHONPATH=. $< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(SETTINGS): $(SETTINGS_DEPS) $(SRCS_DATA)
	$(Q)echo " [ $(@F) ]"
	PYTHONPATH=. $< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)

$(DOCS_SETTINGS): $(DOCS_SETTINGS_DEPS)
	$(Q)echo " [ $(@F) ]"
	PYTHONPATH=. scripts/generate_docs_settings \
		--build $(BUILD_DIR) \
		--resources $(RESOURCES_DIR) \
		--source $(SOURCE_DIR)

$(DOCS_ICON): $(ICON)
	$(Q)echo " [ $(@F) ]"
	mkdir -p $(@D)
	cp $(RESOURCES_GENERATED_DIR)icon.svg $@

$(DOCS_DEVICE_OVERLAY_LIGHT): $(DEVICE_OVERLAY_SRC)
	$(Q)echo " [ $(@F) ]"
	mkdir -p $(@D)
	convert $< -alpha extract $@.orig-alpha.png
	convert $< \
		-alpha on \
		-bordercolor white \
		-border 1 \
		-fill none \
		-fuzz 10% \
		-draw 'matte 0,0 floodfill' \
		-shave 1x1 \
		-alpha extract \
		$@.bg-alpha.png
	convert $@.orig-alpha.png $@.bg-alpha.png -compose Darken -composite -threshold 99% $@.alpha.png
	convert $< $@.alpha.png -alpha off -compose CopyOpacity -composite $@
	$(RM) $@.orig-alpha.png $@.bg-alpha.png $@.alpha.png

$(DOCS_DEVICE_OVERLAY_DARK): $(DEVICE_OVERLAY_SRC)
	$(Q)echo " [ $(@F) ]"
	mkdir -p $(@D)
	convert $< -alpha extract $@.orig-alpha.png
	convert $< \
		-alpha off \
		-bordercolor white \
		-border 1 \
		-fill none \
		-fuzz 36% \
		-draw 'matte 0,0 floodfill' \
		-shave 1x1 \
		-alpha extract \
		$@.external-alpha.png
	convert $@.orig-alpha.png $@.external-alpha.png -compose Darken -composite -threshold 99% $@.alpha.png
	convert $@.external-alpha.png -negate -morphology Dilate Disk:1 $@.external-dilate.png
	convert $@.external-dilate.png $@.alpha.png -compose Multiply -composite $@.edge-mask.png
	convert $< \( +clone -fill '#1d2020' -colorize 100 \) $@.edge-mask.png -compose Over -composite $@.edge-rgb.png
	convert $@.edge-rgb.png $@.alpha.png -alpha off -compose CopyOpacity -composite $@
	$(RM) $@.orig-alpha.png $@.external-alpha.png $@.alpha.png $@.external-dilate.png $@.edge-mask.png $@.edge-rgb.png

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

bo build_optimized: # build project for device in optimized mode
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=optimized build
.PHONY: bo build_optimized

br build_release: # build project for device in release mode
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
		$(FLAG_SIMULATE)

	wait $$SIM_PID
.PHONY: s simulate

st simulate_test: # run simulator w/ tests
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test simulate
.PHONY: st simulate_test

so simulate_optimized: # run simulator width optimized build
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=optimized simulate
.PHONY: so simulate_optimized

sr simulate_release: # run simulator with release build
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release simulate
.PHONY: sr simulate_release

r resources: $(RESOURCES) # generate resources
.PHONY: r resources

$(DOCS_EXPORT_STAMP): FORCE $(DOCS_SETTINGS) $(DOCS_ICON) $(DOCS_DEVICE_OVERLAYS)
	$(Q)echo " [ docs ]"
	rm -rf -- "$(DOCS_OUTPUT_DIR)"
	mkdir -p -- "$(DOCS_OUTPUT_DIR)"
	cp -R "$(DOCS_DIR)." "$(DOCS_OUTPUT_DIR)"
	rm -rf -- "$(DOCS_OUTPUT_DIR)tests"
	touch "$@"

d docs: $(DOCS_EXPORT_STAMP) # build publishable documentation
.PHONY: d docs

t test: $(RESOURCES) # run test
	$(Q)echo " [ test ]"
	PYTHONPATH=. pytest
	node --test docs/tests/*.test.mjs
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
	$(RM) -r bin                                \
		$(BUILD_DIR) $(SRCS_GENERATED_DIR)      \
		$(RESOURCES) $(RESOURCES_GENERATED_DIR) \
		$(DOCS_SETTINGS) $(DOCS_ICON) $(DOCS_DEVICE_OVERLAYS)
.PHONY: c clean

# ---- help ----

h help: # print help message
	$(Q)echo " [ help ]"

	N="\033[m"
	B="\033[1m"
	I="\033[3m"
	U="\033[4m"

	printf "\n"
	printf " Makefile for ConnectIQ project.\n"
	printf "\n"
	printf " %bUsage%b\n" "$$B" "$$N"
	printf "     %bmake%b [%btarget%b] [%barguments%b]...\n" "$$B" "$$N" "$$U" "$$N" "$$U" "$$N"
	printf "\n"
	# ---- targets ----
	printf " %bTargets%b\n" "$$B" "$$N"
	awk -v description_column=$(HELP_DESCRIPTION_COLUMN) -F'#' '\
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
		description_width = description_column - 7; \
		if (max_long > description_width) \
			description_width = max_long; \
		for (i = 1; i <= n; i++) \
			printf "%" padding "s %" max_short "s %-" description_width "s %s\n", "", shorts[i], longs[i], desc[i]; \
	}' $(MAKEFILE_LIST)
	printf "\n"
	# ---- arguments ----
	printf " %bArguments%b\n" "$$B" "$$N"
	awk -v description_column=$(HELP_DESCRIPTION_COLUMN) '\
	/^# ---- arguments ----$$/ { in_arguments = 1; next } \
	in_arguments && /^# ----/ { exit } \
	in_arguments && /^# / { description = substr($$0, 3); next } \
	in_arguments && /^[[:alpha:]_][[:alnum:]_]*[[:space:]]*\?=/ { \
		split($$0, assignment, "?="); \
		name = assignment[1]; \
		default_value = assignment[2]; \
		gsub(/[[:space:]]/, "", name); \
		sub(/^[[:space:]]*/, "", default_value); \
		++n; \
		names[n] = name; \
		descriptions[n] = description; \
		defaults[n] = default_value; \
		if (length(name) > max_name) max_name = length(name); \
		description = ""; \
	} \
	END { \
		description_width = description_column - 6; \
		if (max_name > description_width) \
			description_width = max_name; \
		for (i = 1; i <= n; i++) { \
			printf "     %-" description_width "s %s\n", names[i], descriptions[i]; \
			printf "%" description_column "s\033[3mdefault:\033[m %s\n", "", defaults[i]; \
		} \
	}' $(MAKEFILE_LIST)
	printf "\n"
	# ---- devices ----
	printf " %bDevices%b\n" "$$B" "$$N"
	sed -n 's/.*iq:product id="\(.*\)"\/>/     \1/p' ./manifest.xml
	printf "\n"
	# ---- modes ----
	printf " %bModes%b\n" "$$B" "$$N"
	awk -v description_column=$(HELP_DESCRIPTION_COLUMN) '\
	/^# ---- options ----$$/ { in_options = 1; next } \
	in_options && /^# ----/ { exit } \
	in_options && /^# / { description = substr($$0, 3); next } \
	in_options && /^NAME_SUFFIX\.[[:alnum:]_-]+[[:space:]]*:=/ { \
		split($$1, name_parts, "."); \
		++n; \
		modes[n] = name_parts[2]; \
		descriptions[n] = description; \
		if (length(modes[n]) > max_mode) max_mode = length(modes[n]); \
		description = ""; \
	} \
	END { \
		description_width = description_column - 6; \
		if (max_mode > description_width) \
			description_width = max_mode; \
		for (i = 1; i <= n; i++) \
			printf "     %-" description_width "s %s\n", modes[i], descriptions[i]; \
	}' $(MAKEFILE_LIST)
	printf "\n"
.PHONY: help
