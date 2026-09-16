# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

# ---- arguments ----

# binary name
NAME        ?= phase0
# target device
DEVICE      ?= fr955
# build mode
MODE        ?= debug
# log tag prefix
LOG_PREFIX  ?=
# show commands
V           ?= 0

VALID_MODES := debug test optimized release
ifneq ($(filter $(MODE),$(VALID_MODES)),$(MODE))
$(error Unsupported MODE='$(MODE)'; choose one of: $(VALID_MODES))
endif

# developer key path (provided through the environment or make arguments)
# CONNECTIQ_DEVELOPER_KEY
MONKEYC_PRIVATE_KEY := $(if $(strip $(CONNECTIQ_DEVELOPER_KEY)),--private-key $(CONNECTIQ_DEVELOPER_KEY))

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

LOG_TAG = $(if $(LOG_PREFIX),$(LOG_PREFIX)-$(1),$(1))

PYTHON_FILES := $(shell rg --files -g '*.py') \
	scripts/generate_fonts scripts/generate_icon scripts/generate_settings \
	scripts/generate_site_devices scripts/generate_site_settings scripts/generate_memory_jungle scripts/smoke

SDK_TARGETS := b build build_optimized bo build_release br s simulate st simulate_test so simulate_optimized sr simulate_release deploy

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
ifneq ($(filter $(MODE),optimized release),)
MONKEYC   := node scripts/optimizedc.mjs
else
MONKEYC   := $(SDK_DIR)bin/monkeyc
endif

BUILD_DIR     := build/
IQ            := $(BUILD_DIR)$(NAME).iq
JUNGLE        := monkey.jungle
MEMORY_JUNGLE := $(BUILD_DIR)memory.jungle
JUNGLES       := $(JUNGLE);$(MEMORY_JUNGLE)
MANIFEST      := manifest.xml
OUT           := $(NAME)-$(DEVICE)$(NAME_SUFFIX)
PRG           := $(BUILD_DIR)$(OUT).prg
RSCS          := $(shell find resources/base resources/lang resources/memory -type f ! -path '*/__pycache__/*')
SRCS          := $(shell find source -type f ! -path '*/__pycache__/*')
SRCS_DATA     := $(shell find source/data -type f ! -path '*/__pycache__/*')

SITE_DIR  := site/
SITE_EXPORT_STAMP := $(BUILD_DIR).site.stamp
SITE_OUTPUT_DIR := $(BUILD_DIR)site/
SITE_COPY_STAMP := $(SITE_OUTPUT_DIR).source.stamp
SITE_UI_ASSETS := foundation.css components.css theme.js scroll-top.js
SITE_UI_DIR := .site-ui
SITE_UI_REMOTE_REPOSITORY := https://github.com/dawikur/site-ui.git
SITE_UI_STAMP    := $(SITE_UI_DIR)/.fetch.stamp
SITE_FILES := $(shell find site -type f \
	! -name 'icon.svg' \
	! -name 'fr955-light.png' \
	! -name 'fr955-dark.png' \
	! -name 'settings-data.js' \
	! -name 'devices-data.js')
VENV_DIR    := .venv
VENV_PYTHON := $(VENV_DIR)/bin/python
VENV_STAMP  := $(VENV_DIR)/.installed.stamp

ifndef SITE_UI_REPOSITORY
SITE_UI_REPOSITORY := $(SITE_UI_REMOTE_REPOSITORY)

ifneq ($(wildcard $(CURDIR)/../site-ui/.git),)
SITE_UI_LOCAL_REMOTE := $(shell \
  git -C "$(CURDIR)/../site-ui" remote get-url origin 2>/dev/null \
    | sed -E 's|^git@github.com:|https://github.com/|; \
              s|^ssh://git@github.com/|https://github.com/|; \
              s|\.git$$||')
SITE_UI_EXPECTED_REMOTE := $(shell \
  printf '%s' "$(SITE_UI_REMOTE_REPOSITORY)" \
    | sed -E 's|^git@github.com:|https://github.com/|; \
              s|^ssh://git@github.com/|https://github.com/|; \
              s|\.git$$||')

ifeq ($(SITE_UI_LOCAL_REMOTE),$(SITE_UI_EXPECTED_REMOTE))
SITE_UI_REPOSITORY := $(CURDIR)/../site-ui
endif
endif
endif

SRCS_GENERATED_DIR  := source/generated/

RESOURCES_DIR           := resources/
RESOURCES_BASE_DIR      := $(RESOURCES_DIR)base/
RESOURCES_GENERATED_DIR := $(RESOURCES_BASE_DIR)generated/

SOURCE_DIR          := source/

SCRIPT_DEPS         := $(shell find scripts/utils -type f -name '*.py')
DATA_FONTS_DEPS     := $(shell find data/fonts -type f ! -path '*/__pycache__/*')
DATA_SETTINGS_DEPS  := $(shell find data/settings -type f ! -path '*/__pycache__/*')
DATA_DEVICES_DEPS   := $(shell find data/devices -type f -name '*.py')
RESOURCE_STRINGS    := $(shell find resources -name strings.xml -type f)

ICON_DEPS           := scripts/generate_icon                      \
                       $(SCRIPT_DEPS)                             \
                       $(DATA_FONTS_DEPS)                         \
                       $(RESOURCE_STRINGS)
ICON_STAMP          := $(BUILD_DIR).icon.stamp
FONTS_DEPS          := scripts/generate_fonts                     \
                       $(SCRIPT_DEPS)                             \
                       $(DATA_FONTS_DEPS)                          \
                       $(RESOURCE_STRINGS)
FONTS_STAMP         := $(BUILD_DIR).fonts.stamp
SETTINGS_DEPS       := scripts/generate_settings                  \
                       $(SCRIPT_DEPS)                             \
                       $(DATA_FONTS_DEPS)                          \
                       $(DATA_SETTINGS_DEPS)
SETTINGS_STAMP      := $(BUILD_DIR).settings.stamp
SITE_SETTINGS_DEPS  := scripts/generate_site_settings             \
                       scripts/utils/site_settings.py             \
                       $(SETTINGS_STAMP)                           \
                       $(RESOURCE_STRINGS)
SITE_SETTINGS       := $(SITE_OUTPUT_DIR)settings-data.js
SITE_DEVICES_DEPS   := scripts/generate_site_devices              \
                       scripts/utils/site_devices.py              \
                       $(MANIFEST)                                \
                       $(DATA_DEVICES_DEPS)
SITE_DEVICES        := $(SITE_OUTPUT_DIR)devices-data.js
SITE_ICON           := $(SITE_DIR)assets/icon.svg
DEVICE_OVERLAY_SRC  := $(SITE_DIR)assets/fr955.png
SITE_DEVICE_OVERLAY_LIGHT := $(SITE_DIR)assets/fr955-light.png
SITE_DEVICE_OVERLAY_DARK  := $(SITE_DIR)assets/fr955-dark.png
SITE_DEVICE_OVERLAYS := $(SITE_DEVICE_OVERLAY_LIGHT) $(SITE_DEVICE_OVERLAY_DARK)

RESOURCES := $(ICON_STAMP) $(FONTS_STAMP) $(SETTINGS_STAMP)

MEMORY_JUNGLE_DEPS := scripts/generate_memory_jungle \
                      scripts/utils/memory_jungle.py \
                      $(MANIFEST) \
                      $(DATA_DEVICES_DEPS)

MONKEYC_DEPS := $(if $(filter optimized release,$(MODE)),scripts/optimizedc.mjs,)
MONKEYC_KEY_DEPS := $(if $(filter release,$(MODE)),$(strip $(CONNECTIQ_DEVELOPER_KEY)),)

PRG_DEPS := $(JUNGLE) $(MEMORY_JUNGLE) $(MONKEYC_DEPS) $(MONKEYC_KEY_DEPS) $(SRCS) $(RSCS) \
            $(ICON_STAMP) $(FONTS_STAMP) $(SETTINGS_STAMP)

# ---- settings ----

.DEFAULT_GOAL := build
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -e -o pipefail -c
SHELL := /bin/bash

MAKEFLAGS += --no-print-directory

# ---- targets ----

ifneq ($(strip $(SITE_UI_REFRESH)),)
$(SITE_UI_STAMP): FORCE_SITE_UI
endif

FORCE_SITE_UI:
.PHONY: FORCE_SITE_UI

$(SITE_UI_STAMP):
	$(Q)echo " [ $(call LOG_TAG,fetch-site-ui) ]"
	if [ ! -d "$(SITE_UI_DIR)/.git" ]; then git clone --no-checkout -- "$(SITE_UI_REPOSITORY)" "$(SITE_UI_DIR)"; fi
	git -C "$(SITE_UI_DIR)" fetch --prune origin main
	git -C "$(SITE_UI_DIR)" checkout --detach FETCH_HEAD
	touch "$@"

$(VENV_STAMP): requirements.txt
	$(Q)python3 -m venv "$(VENV_DIR)"
	$(Q)$(VENV_PYTHON) -m pip install -r requirements.txt
	touch "$@"

$(PRG): $(PRG_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	$(MONKEYC) \
		--jungles "$(JUNGLES)" \
		--device $(DEVICE) \
		--output $@ \
		--warn \
		$(MONKEYC_PRIVATE_KEY) \
		$(FLAG_MONKEYC)

$(IQ): $(PRG_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	$(MONKEYC) \
		--jungles "$(JUNGLES)" \
		--output $@ \
		--warn \
		$(MONKEYC_PRIVATE_KEY) \
		$(FLAG_MONKEYC)

$(FONTS_STAMP): $(FONTS_DEPS) $(VENV_STAMP)
	$(Q)echo " [ $(call LOG_TAG,fonts) ]"
	mkdir -p "$(@D)"
	PYTHONPATH=. $(VENV_PYTHON) $< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)
	touch "$@"

$(ICON_STAMP): $(ICON_DEPS) $(VENV_STAMP)
	$(Q)echo " [ $(call LOG_TAG,icons) ]"
	mkdir -p "$(@D)"
	PYTHONPATH=. $(VENV_PYTHON) $< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)
	touch "$@"

$(SETTINGS_STAMP): $(SETTINGS_DEPS) $(SRCS_DATA) $(VENV_STAMP)
	$(Q)echo " [ $(call LOG_TAG,settings) ]"
	mkdir -p "$(@D)"
	PYTHONPATH=. $(VENV_PYTHON) $< --build $(BUILD_DIR) --resources $(RESOURCES_DIR) --source $(SOURCE_DIR)
	touch "$@"

$(MEMORY_JUNGLE): $(MEMORY_JUNGLE_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. python3 scripts/generate_memory_jungle --output $@

$(SITE_SETTINGS): $(VENV_STAMP) $(SITE_COPY_STAMP) $(SITE_SETTINGS_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_settings \
		--build $(BUILD_DIR) \
		--resources $(RESOURCES_DIR) \
		--source $(SOURCE_DIR) \
		--output $(SITE_SETTINGS)

$(SITE_DEVICES): $(VENV_STAMP) $(SITE_COPY_STAMP) $(SITE_DEVICES_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_devices \
		--output $(SITE_DEVICES)

$(SITE_ICON): $(ICON_STAMP)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	mkdir -p $(@D)
	cp $(RESOURCES_GENERATED_DIR)icon.svg $@

$(SITE_DEVICE_OVERLAY_LIGHT): $(DEVICE_OVERLAY_SRC)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	mkdir -p $(@D)
	convert $< -alpha extract $@.orig-alpha.png
	convert $< \
		-alpha on \
		-bordercolor white \
		-border 1 \
		-fill none \
		-fuzz 10% \
		-draw 'color 0,0 floodfill' \
		-shave 1x1 \
		-alpha extract \
		$@.bg-alpha.png
	convert $@.orig-alpha.png $@.bg-alpha.png -compose Darken -composite -threshold 99% $@.alpha.png
	convert $< $@.alpha.png -alpha off -compose CopyOpacity -composite $@
	$(RM) $@.orig-alpha.png $@.bg-alpha.png $@.alpha.png

$(SITE_DEVICE_OVERLAY_DARK): $(DEVICE_OVERLAY_SRC)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	mkdir -p $(@D)
	convert $< -alpha extract $@.orig-alpha.png
	convert $< \
		-alpha off \
		-bordercolor white \
		-border 1 \
		-fill none \
		-fuzz 36% \
		-draw 'color 0,0 floodfill' \
		-shave 1x1 \
		-alpha extract \
		$@.external-alpha.png
	convert $@.orig-alpha.png $@.external-alpha.png -compose Darken -composite -threshold 99% $@.alpha.png
	convert $@.external-alpha.png -negate -morphology Dilate Disk:1 $@.external-dilate.png
	convert $@.external-dilate.png $@.alpha.png -compose Multiply -composite $@.edge-mask.png
	convert $< \( +clone -fill '#1d2020' -colorize 100 \) $@.edge-mask.png -compose Over -composite $@.edge-rgb.png
	convert $@.edge-rgb.png $@.alpha.png -alpha off -compose CopyOpacity -composite $@
	$(RM) $@.orig-alpha.png $@.external-alpha.png $@.alpha.png $@.external-dilate.png $@.edge-mask.png $@.edge-rgb.png

# ---- aliases ----

ifneq ($(MODE),release)
iq:
	$(Q)echo " [ $(call LOG_TAG,iq) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release iq
else
iq: $(IQ) # build iq project
	$(Q)echo " [ $(call LOG_TAG,iq) ]"
endif
.PHONY: iq

b build: $(PRG) # build project for device
	$(Q)echo " [ $(call LOG_TAG,build) ]"
.PHONY: b build

bt build_test: # build project for device w/ tests
	$(Q)echo " [ $(call LOG_TAG,build_test) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test build
.PHONY: bt build_test

bo build_optimized: # build project for device in optimized mode
	$(Q)echo " [ $(call LOG_TAG,build_optimized) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=optimized build
.PHONY: bo build_optimized

br build_release: # build project for device in release mode
	$(Q)echo " [ $(call LOG_TAG,build_release) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release build
.PHONY: br build_release

s simulate: build # run simulator
	$(Q)echo " [ $(call LOG_TAG,simulate) ] $(MODE)"
	cleanup() {
		if [[ -n "$$SIM_PID" ]] && kill -0 "$$SIM_PID" 2>/dev/null; then
			kill "$$SIM_PID"
			wait "$$SIM_PID" || true
		fi
	}
	trap cleanup EXIT
	$(CONNECTIQ)&
	SIM_PID=$$!
	sleep 3
	if ! kill -0 "$$SIM_PID" 2>/dev/null; then
		wait "$$SIM_PID"
		exit 1
	fi
	$(MONKEYDO) \
		$(PRG) \
		$(DEVICE) \
		-a $(BUILD_DIR)$(OUT)-settings.json:GARMIN/Settings/$(OUT)-settings.json \
		$(FLAG_SIMULATE)

	wait "$$SIM_PID"
	SIM_PID=
	trap - EXIT
.PHONY: s simulate

st simulate_test: # run simulator w/ tests
	$(Q)echo " [ $(call LOG_TAG,simulate_test) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test simulate
.PHONY: st simulate_test

so simulate_optimized: # run simulator width optimized build
	$(Q)echo " [ $(call LOG_TAG,simulate_optimized) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=optimized simulate
.PHONY: so simulate_optimized

sr simulate_release: # run simulator with release build
	$(Q)echo " [ $(call LOG_TAG,simulate_release) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release simulate
.PHONY: sr simulate_release

r resources: $(RESOURCES) # generate resources
	$(Q)echo " [ $(call LOG_TAG,resources) ]"
.PHONY: r resources

$(SITE_COPY_STAMP): $(SITE_FILES) $(SITE_ICON) $(SITE_DEVICE_OVERLAYS) $(SITE_UI_STAMP)
	$(Q)echo " [ $(call LOG_TAG,site-copy) ]"
	rm -rf -- "$(SITE_OUTPUT_DIR)"
	mkdir -p -- "$(SITE_OUTPUT_DIR)"
	cp -R "$(SITE_DIR)." "$(SITE_OUTPUT_DIR)"
	mkdir -p "$(SITE_OUTPUT_DIR)assets/site-ui"
	cp $(addprefix $(SITE_UI_DIR)/,$(SITE_UI_ASSETS)) "$(SITE_OUTPUT_DIR)assets/site-ui/"
	rm -rf -- "$(SITE_OUTPUT_DIR)tests"
	touch "$@"

$(SITE_EXPORT_STAMP): $(VENV_STAMP) $(SITE_COPY_STAMP) $(SITE_SETTINGS) $(SITE_DEVICES)
	$(Q)echo " [ $(call LOG_TAG,site) ]"
	touch "$@"

site: $(SITE_EXPORT_STAMP) # build publishable site
	$(Q)echo " [ $(call LOG_TAG,site) ]"
.PHONY: s site

site-update: # fetch the latest site UI and rebuild the site
	$(Q)$(MAKE) SITE_UI_REFRESH=1 site
.PHONY: site-update

t test: $(RESOURCES) $(VENV_STAMP) # run test
	$(Q)echo " [ $(call LOG_TAG,test) ]"
	PYTHONPATH=. $(VENV_PYTHON) -m pytest \
		--cov \
		--cov-report=term-missing \
		--cov-fail-under=100
	node --test site/tests/*.test.mjs
.PHONY: t test

l lint: $(VENV_STAMP) # run static checks
	$(Q)echo " [ $(call LOG_TAG,lint) ]"
	$(Q)$(VENV_PYTHON) -m isort $(PYTHON_FILES)
	$(Q)$(VENV_PYTHON) -m black $(PYTHON_FILES)
	$(Q)$(VENV_PYTHON) -m basedpyright $(PYTHON_FILES)
	$(Q)$(VENV_PYTHON) -m pylint $(PYTHON_FILES)
.PHONY: l lint

smoke: $(VENV_STAMP) # run smoke test
	$(Q)echo " [ $(call LOG_TAG,smoke) ]"
	$(Q)$(VENV_PYTHON) scripts/smoke
.PHONY: smoke

ifneq ($(MODE),release)
d deploy:
	$(Q)echo " [ $(call LOG_TAG,deploy) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release deploy
else
d deploy: build # deploy release binary to watch
	$(Q)i=0; while ! gio mount -l | grep -q "mtp://091e_"; do
		set -- ⠋ ⠙ ⠸ ⢰ ⣠ ⣄ ⡆  ⠇
		shift $$((i % 8))
		printf "\r [ $(call LOG_TAG,deploy) ] %s" "$$1"
		printf "\033[D"
		i=$$((i+1))
		sleep .1
	done; printf "\r\033[K"

	$(Q)echo " [ $(call LOG_TAG,deploy) ]"
	GVFS="/run/user/$$(id -u)/gvfs"
	MOUNT="$$(ls "$$GVFS" | grep 'mtp:host=' | head -n1)"
	TARGET="$$GVFS/$$MOUNT/Internal Storage/GARMIN/Apps"
	gio copy $(PRG) "$$TARGET/"
endif
.PHONY: d deploy

c clean: # remove build directory and files
	$(Q)echo " [ $(call LOG_TAG,clean) ]"
	$(RM) -r bin                                \
		$(BUILD_DIR) $(SRCS_GENERATED_DIR)      \
		$(RESOURCES) $(RESOURCES_GENERATED_DIR) \
		$(RESOURCES_DIR)generated                \
		$(RESOURCES_DIR)memory/low/generated    \
		$(RESOURCES_DIR)memory/medium/generated \
		$(RESOURCES_DIR)memory/high/generated   \
		$(SITE_SETTINGS) $(SITE_DEVICES) $(SITE_DIR)settings-data.js $(SITE_DIR)devices-data.js \
		$(SITE_ICON) $(SITE_DEVICE_OVERLAYS) \
		$(VENV_DIR) .build-venv .dev-venv .site-venv $(SITE_UI_DIR) \
		.mypy_cache .pytest_cache .coverage $(wildcard *.egg-info)
.PHONY: c clean

# ---- help ----

h help: # print help message
	$(Q)echo " [ $(call LOG_TAG,help) ]"

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
	} \
	END { \
		for (i = 1; i <= n; i++) { \
			label = shorts[i]; \
			indent = 5; \
			if (longs[i] != "") { \
				label = label " " longs[i]; \
				indent = 4 - length(shorts[i]); \
			} \
			padding = description_column - indent - length(label) - 1; \
			if (padding < 1) padding = 1; \
			printf "%*s%s%*s%s\n", indent, "", label, padding, "", desc[i]; \
		} \
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
			printf "%" (description_width + 6) "s\033[3mdefault:\033[m %s\n", "", defaults[i]; \
		} \
	}' $(MAKEFILE_LIST)
	printf "\n"
	# ---- devices ----
	printf " %bDevices%b\n" "$$B" "$$N"
	sed -n 's/.*iq:product id="\(.*\)"\/>/     \1/p' $(MANIFEST)
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
