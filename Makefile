# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

# ---- arguments ----

# binary name
NAME        ?= phase0
# target device
DEVICE      ?= fr955
# build mode
MODE        ?= debug
# application channel
CHANNEL     ?= developer
# log tag prefix
LOG_PREFIX  ?=
# show commands
V           ?= 0

VALID_MODES := debug test optimized release
ifneq ($(filter $(MODE),$(VALID_MODES)),$(MODE))
$(error Unsupported MODE='$(MODE)'; choose one of: $(VALID_MODES))
endif

PACKAGE_TARGETS := alpha beta iq
ifneq ($(filter $(PACKAGE_TARGETS),$(MAKECMDGOALS)),)
ifneq ($(origin MODE),file)
ifneq ($(MODE),release)
$(error alpha, beta and iq require MODE=release)
endif
endif
endif

VALID_CHANNELS := developer alpha beta release
CHANNEL_DESCRIPTION.developer := Local development builds
CHANNEL_DESCRIPTION.alpha     := Alpha Store listing
CHANNEL_DESCRIPTION.beta      := Beta Store listing
CHANNEL_DESCRIPTION.release   := Public Store listing
ifneq ($(filter $(CHANNEL),$(VALID_CHANNELS)),$(CHANNEL))
$(error Unsupported CHANNEL='$(CHANNEL)'; choose one of: $(VALID_CHANNELS))
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
	scripts/generate_resources_fonts scripts/generate_resources_icon scripts/generate_site_icon \
	scripts/generate_screenshots \
	scripts/generate_manifest \
	scripts/generate_resources_settings \
	scripts/generate_site_devices scripts/generate_site_settings scripts/generate_site_screenshots \
	scripts/generate_resources_jungle scripts/smoke

SDK_TARGETS := b build build_optimized bo build_release br s simulate st simulate_test so simulate_optimized sr simulate_release deploy alpha beta iq

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
IQ            := $(BUILD_DIR)$(NAME)$(if $(filter release,$(CHANNEL)),,-$(CHANNEL)).iq
JUNGLE        := monkey.jungle
RESOURCES_JUNGLE := $(BUILD_DIR)resources.jungle
MANIFEST_TEMPLATE := manifest.xml.tmpl
MANIFEST      := $(BUILD_DIR)manifests/$(CHANNEL).xml
RELEASE_MANIFEST := $(BUILD_DIR)manifests/release.xml
CHANNEL_JUNGLE := $(BUILD_DIR)manifests/$(CHANNEL).jungle
JUNGLES       := $(JUNGLE);$(RESOURCES_JUNGLE);$(CHANNEL_JUNGLE)
OUT           := $(NAME)-$(DEVICE)$(NAME_SUFFIX)$(if $(filter release,$(CHANNEL)),,_$(CHANNEL))
APP_SETTINGS  := $(shell printf '%s' '$(OUT)' | tr '[:lower:]' '[:upper:]')-settings.json
PRG           := $(BUILD_DIR)$(OUT).prg
RESOURCE_DIRS := resources/base resources/lang $(wildcard resources/memory resources/fonts)
RSCS          := $(shell find $(RESOURCE_DIRS) -type f ! -path '*/__pycache__/*')
SRCS          := $(shell find source -type f ! -path '*/__pycache__/*')
SRCS_DATA     := $(shell find source/data -type f ! -path '*/__pycache__/*')

SITE_DIR  := site/
SITE_EXPORT_STAMP := $(BUILD_DIR).site.stamp
SITE_OUTPUT_DIR := $(BUILD_DIR)site/
SITE_COPY_STAMP := $(SITE_OUTPUT_DIR).source.stamp
STORE_OUTPUT_DIR := $(BUILD_DIR)store/
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

ICON_DEPS           := scripts/generate_resources_icon            \
                       $(SCRIPT_DEPS)                             \
                       $(DATA_FONTS_DEPS)                         \
                       $(RESOURCE_STRINGS)
ICON_STAMP          := $(BUILD_DIR).icon.stamp
STORE_ICONS         := $(STORE_OUTPUT_DIR)icon_128.png $(STORE_OUTPUT_DIR)icon_512.png $(STORE_OUTPUT_DIR)icon_128_amoled.png
STORE_HERO          := $(STORE_OUTPUT_DIR)hero.png
STORE_VARIANTS      := $(foreach channel,alpha beta,$(addprefix $(STORE_OUTPUT_DIR)$(channel)/,icon_128.png icon_512.png hero.png data-rich.png))
STORE_HERO_SCREENSHOTS := $(addprefix $(SITE_DIR)assets/screenshots/,data-rich.png data-rich-aod.png)
STORE_SCREENSHOT_SOURCES := $(filter-out %-aod.png,$(wildcard $(SITE_DIR)assets/screenshots/*.png)) \
                            $(SITE_DIR)assets/screenshots/data-rich-aod.png
STORE_SCREENSHOTS := $(patsubst $(SITE_DIR)assets/screenshots/%,$(STORE_OUTPUT_DIR)%,$(STORE_SCREENSHOT_SOURCES))
SCREENSHOTS_STAMP   := $(BUILD_DIR).screenshots.stamp
FONTS_DEPS          := scripts/generate_resources_fonts            \
                       $(SCRIPT_DEPS)                             \
                       $(DATA_FONTS_DEPS)                          \
                       $(RESOURCE_STRINGS)
FONTS_STAMP         := $(BUILD_DIR).fonts.stamp
SETTINGS_DEPS       := scripts/generate_resources_settings         \
                       $(SCRIPT_DEPS)                             \
                       $(DATA_FONTS_DEPS)                          \
                       $(DATA_SETTINGS_DEPS)
SETTINGS_STAMP      := $(BUILD_DIR).settings.stamp
SITE_SETTINGS_DEPS  := scripts/generate_site_settings             \
                       scripts/utils/site_settings.py             \
                       $(RELEASE_MANIFEST)                       \
                       $(SETTINGS_STAMP)                           \
                       $(RESOURCE_STRINGS)
SITE_SETTINGS       := $(SITE_OUTPUT_DIR)settings-data.js
SITE_SCREENSHOTS_DEPS := scripts/generate_site_screenshots        \
	                     scripts/utils/site_screenshots.py        \
	                     scripts/utils/store_screenshots.py       \
	                     data/screenshots.py                      \
	                     $(DATA_SETTINGS_DEPS)                    \
	                     $(SRCS_DATA)
SITE_SCREENSHOTS    := $(SITE_OUTPUT_DIR)screenshots-data.js
SITE_DEVICES_DEPS   := scripts/generate_site_devices              \
                       scripts/utils/site_devices.py              \
                       $(RELEASE_MANIFEST)                        \
                       $(DATA_DEVICES_DEPS)
SITE_DEVICES        := $(SITE_OUTPUT_DIR)devices-data.js
SITE_ICON           := $(SITE_OUTPUT_DIR)assets/icon.svg
DEVICE_OVERLAY_SRC  := $(SITE_DIR)assets/fr955.png
SITE_DEVICE_OVERLAY_SRC := $(SITE_OUTPUT_DIR)assets/fr955.png
SITE_DEVICE_OVERLAY_LIGHT := $(SITE_OUTPUT_DIR)assets/fr955-light.png
SITE_DEVICE_OVERLAY_DARK  := $(SITE_OUTPUT_DIR)assets/fr955-dark.png
SITE_DEVICE_OVERLAYS := $(SITE_DEVICE_OVERLAY_LIGHT) $(SITE_DEVICE_OVERLAY_DARK)

RESOURCES := $(ICON_STAMP) $(FONTS_STAMP) $(SETTINGS_STAMP)

RESOURCES_JUNGLE_DEPS := scripts/generate_resources_jungle \
                      scripts/utils/resources_jungle.py \
                      $(RELEASE_MANIFEST) \
                      $(DATA_DEVICES_DEPS)

MONKEYC_DEPS := $(if $(filter optimized release,$(MODE)),scripts/optimizedc.mjs,)
MONKEYC_KEY_DEPS := $(if $(filter release,$(MODE)),$(strip $(CONNECTIQ_DEVELOPER_KEY)),)

PRG_DEPS := $(JUNGLE) $(RESOURCES_JUNGLE) $(MANIFEST) $(CHANNEL_JUNGLE) $(MONKEYC_DEPS) $(MONKEYC_KEY_DEPS) $(SRCS) $(RSCS) \
            $(ICON_STAMP) $(FONTS_STAMP) $(SETTINGS_STAMP)
SCREENSHOTS_DEPS := Makefile scripts/generate_screenshots $(SCRIPT_DEPS) \
                    data/screenshots.py $(DATA_SETTINGS_DEPS) $(DATA_DEVICES_DEPS) \
                    $(RELEASE_MANIFEST) scripts/optimizedc.mjs package.json package-lock.json \
                    $(PRG_DEPS)

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

$(BUILD_DIR)manifests/%.xml: $(MANIFEST_TEMPLATE) scripts/generate_manifest scripts/utils/app_channels.py
	$(Q)PYTHONPATH=. python3 scripts/generate_manifest --channel $* --output $@

$(BUILD_DIR)manifests/%.jungle: $(BUILD_DIR)manifests/%.xml
	$(Q)printf 'project.manifest = %s\n' '$(abspath $(BUILD_DIR)manifests/$*.xml)' > $@

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
	$(Q)test "$(CHANNEL)" != developer
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

$(RESOURCES_JUNGLE): $(RESOURCES_JUNGLE_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. python3 scripts/generate_resources_jungle --manifest $(RELEASE_MANIFEST) --output $@

$(SITE_SETTINGS): $(VENV_STAMP) $(SITE_COPY_STAMP) $(SITE_SETTINGS_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_settings \
		--manifest $(RELEASE_MANIFEST) \
		--build $(BUILD_DIR) \
		--resources $(RESOURCES_DIR) \
		--source $(SOURCE_DIR) \
		--output $(SITE_SETTINGS)

$(SITE_DEVICES): $(VENV_STAMP) $(SITE_COPY_STAMP) $(SITE_DEVICES_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_devices \
		--manifest $(RELEASE_MANIFEST) \
		--output $(SITE_DEVICES)

$(SITE_SCREENSHOTS): $(VENV_STAMP) $(SITE_COPY_STAMP) $(SITE_SCREENSHOTS_DEPS)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_screenshots \
		--output $(SITE_SCREENSHOTS)

$(SITE_ICON): $(ICON_STAMP) $(SITE_COPY_STAMP)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	mkdir -p $(@D)
	cp $(RESOURCES_GENERATED_DIR)icon.svg $@

$(SITE_DEVICE_OVERLAY_LIGHT): $(SITE_COPY_STAMP)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	mkdir -p $(@D)
	convert $(SITE_DEVICE_OVERLAY_SRC) -alpha extract $@.orig-alpha.png
	convert $(SITE_DEVICE_OVERLAY_SRC) \
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
	convert $(SITE_DEVICE_OVERLAY_SRC) $@.alpha.png -alpha off -compose CopyOpacity -composite $@
	$(RM) $@.orig-alpha.png $@.bg-alpha.png $@.alpha.png

$(SITE_DEVICE_OVERLAY_DARK): $(SITE_COPY_STAMP)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	mkdir -p $(@D)
	convert $(SITE_DEVICE_OVERLAY_SRC) -alpha extract $@.orig-alpha.png
	convert $(SITE_DEVICE_OVERLAY_SRC) \
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
	convert $(SITE_DEVICE_OVERLAY_SRC) \( +clone -fill '#1d2020' -colorize 100 \) $@.edge-mask.png -compose Over -composite $@.edge-rgb.png
	convert $@.edge-rgb.png $@.alpha.png -alpha off -compose CopyOpacity -composite $@
	$(RM) $@.orig-alpha.png $@.external-alpha.png $@.alpha.png $@.external-dilate.png $@.edge-mask.png $@.edge-rgb.png

# ---- aliases ----

b build: $(PRG) # build developer PRG for device
	$(Q)echo " [ $(call LOG_TAG,build) ]"
.PHONY: b build

bt build_test: # build developer PRG with tests
	$(Q)echo " [ $(call LOG_TAG,build_test) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test CHANNEL=$(CHANNEL) build
.PHONY: bt build_test

bo build_optimized: # build developer PRG in optimized mode
	$(Q)echo " [ $(call LOG_TAG,build_optimized) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=optimized CHANNEL=$(CHANNEL) build
.PHONY: bo build_optimized

br build_release: # build developer PRG in release mode
	$(Q)echo " [ $(call LOG_TAG,build_release) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release CHANNEL=$(CHANNEL) build
.PHONY: br build_release

alpha: # build alpha IQ package
	$(Q)$(MAKE) NAME=$(NAME) MODE=release CHANNEL=alpha $(BUILD_DIR)$(NAME)-alpha.iq
.PHONY: alpha

beta: # build beta IQ package
	$(Q)$(MAKE) NAME=$(NAME) MODE=release CHANNEL=beta $(BUILD_DIR)$(NAME)-beta.iq
.PHONY: beta

iq: # build release IQ package
	$(Q)$(MAKE) NAME=$(NAME) MODE=release CHANNEL=release $(BUILD_DIR)$(NAME).iq
.PHONY: iq

s simulate: build # run simulator
	$(Q)echo " [ $(call LOG_TAG,simulate) ] $(MODE)"
	cleanup() {
		if [[ -n "$$TEST_LOG" ]]; then
			rm -f "$$TEST_LOG"
		fi
		if [[ -n "$$SIM_PID" ]] && kill -0 "$$SIM_PID" 2>/dev/null; then
			kill "$$SIM_PID"
			wait "$$SIM_PID" || true
		fi
	}
	trap cleanup EXIT
	SIMULATOR="$(CONNECTIQ)"
	if [[ "$$(uname -s)" == Linux ]]; then
		SIMULATOR="$(SDK_DIR)bin/simulator"
	fi
	"$$SIMULATOR" &
	SIM_PID=$$!
	sleep 3
	if ! kill -0 "$$SIM_PID" 2>/dev/null; then
		wait "$$SIM_PID"
		exit 1
	fi
	MONKEYDO_STATUS=0
	if [[ "$(MODE)" == test ]]; then
		TEST_LOG=$$(mktemp)
		# SDK 9.2.0 expects an extra space in the test summary and returns 1
		# even when every test passes. Require an explicit successful summary.
		$(MONKEYDO) $(PRG) $(DEVICE) \
			-a $(BUILD_DIR)$(OUT)-settings.json:GARMIN/Settings/$(APP_SETTINGS) \
			$(FLAG_SIMULATE) 2>&1 | tee "$$TEST_LOG" || MONKEYDO_STATUS=$$?
		if (( MONKEYDO_STATUS > 1 )) || \
			! grep -Eq '^PASSED \(passed=[1-9][0-9]*, failed=0 *, errors=0\)[[:space:]]*$$' "$$TEST_LOG" || \
			grep -Eq 'Encountered an app crash\.|^[[:space:]]*(Error:|ERROR\b)|\b(FAIL|FAILED)\b' "$$TEST_LOG"; then
			echo "Connect IQ tests failed or did not report a successful summary (monkeydo exit $$MONKEYDO_STATUS)." >&2
			exit 1
		fi
		exit 0
	fi
	$(MONKEYDO) \
		$(PRG) \
		$(DEVICE) \
		-a $(BUILD_DIR)$(OUT)-settings.json:GARMIN/Settings/$(APP_SETTINGS) \
		$(FLAG_SIMULATE)

	wait "$$SIM_PID"
	SIM_PID=
	trap - EXIT
.PHONY: s simulate

st simulate_test: # run simulator w/ tests
	$(Q)echo " [ $(call LOG_TAG,simulate_test) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=test CHANNEL=$(CHANNEL) simulate
.PHONY: st simulate_test

so simulate_optimized: # run simulator width optimized build
	$(Q)echo " [ $(call LOG_TAG,simulate_optimized) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=optimized CHANNEL=$(CHANNEL) simulate
.PHONY: so simulate_optimized

sr simulate_release: # run simulator with release build
	$(Q)echo " [ $(call LOG_TAG,simulate_release) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release CHANNEL=$(CHANNEL) simulate
.PHONY: sr simulate_release

$(STORE_OUTPUT_DIR)icon_128_amoled.png: $(ICON_DEPS) scripts/generate_site_icon $(VENV_STAMP)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_icon \
		--font-profile amoled \
		--output $@ \
		--size 128

$(STORE_OUTPUT_DIR)icon_%.png: $(ICON_STAMP) scripts/generate_site_icon
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_icon \
		--input $(RESOURCES_GENERATED_DIR)icon.svg \
		--output $@ \
		--size $*

$(STORE_OUTPUT_DIR)%/icon_128.png: $(ICON_STAMP) scripts/generate_site_icon scripts/utils/store_ribbon.py
	$(Q)PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_icon \
		--input $(RESOURCES_GENERATED_DIR)icon.svg \
		--output $@ \
		--size 128 \
		--channel $*

$(STORE_OUTPUT_DIR)%/icon_512.png: $(ICON_STAMP) scripts/generate_site_icon scripts/utils/store_ribbon.py
	$(Q)PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_icon \
		--input $(RESOURCES_GENERATED_DIR)icon.svg \
		--output $@ \
		--size 512 \
		--channel $*

$(STORE_HERO): scripts/generate_site_hero $(STORE_HERO_SCREENSHOTS) $(VENV_STAMP)
	$(Q)echo " [ $(call LOG_TAG,$(@F)) ]"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_hero \
		--screenshots $(SITE_DIR)assets/screenshots \
		--output $@

$(STORE_OUTPUT_DIR)%/hero.png: scripts/generate_site_hero scripts/utils/store_ribbon.py $(STORE_HERO_SCREENSHOTS) $(VENV_STAMP)
	$(Q)PYTHONPATH=. $(VENV_PYTHON) scripts/generate_site_hero \
		--screenshots $(SITE_DIR)assets/screenshots \
		--output $@ \
		--channel $*

$(STORE_OUTPUT_DIR)%/data-rich.png: $(SITE_DIR)assets/screenshots/data-rich.png scripts/utils/store_ribbon.py $(VENV_STAMP)
	$(Q)PYTHONPATH=. $(VENV_PYTHON) -m scripts.utils.store_ribbon \
		--input $< \
		--output $@ \
		--channel $*

$(STORE_SCREENSHOTS): $(STORE_OUTPUT_DIR)%: $(SITE_DIR)assets/screenshots/%
	$(Q)mkdir -p $(STORE_OUTPUT_DIR)
	cp $< $@

$(SCREENSHOTS_STAMP): $(SCREENSHOTS_DEPS) $(STORE_ICONS) $(VENV_STAMP)
	$(Q)echo " [ $(call LOG_TAG,screenshots) ]"
	$(RM) "$@"
	PYTHONPATH=. $(VENV_PYTHON) scripts/generate_screenshots \
		--manifest $(RELEASE_MANIFEST) \
		--build-dir $(BUILD_DIR) \
		--output-dir $(SITE_DIR)assets/screenshots
	touch "$@"

x screenshots: $(SCREENSHOTS_STAMP) # generate Connect IQ Store assets and screenshots
	$(Q)$(MAKE) $(STORE_HERO)
.PHONY: x screenshots

$(SITE_COPY_STAMP): $(SITE_FILES) $(SITE_UI_STAMP)
	$(Q)echo " [ $(call LOG_TAG,site-copy) ]"
	rm -rf -- "$(SITE_OUTPUT_DIR)"
	mkdir -p -- "$(SITE_OUTPUT_DIR)"
	cp -R "$(SITE_DIR)." "$(SITE_OUTPUT_DIR)"
	mkdir -p "$(SITE_OUTPUT_DIR)assets/site-ui"
	cp $(addprefix $(SITE_UI_DIR)/,$(SITE_UI_ASSETS)) "$(SITE_OUTPUT_DIR)assets/site-ui/"
	rm -rf -- "$(SITE_OUTPUT_DIR)tests"
	touch "$@"

$(SITE_EXPORT_STAMP): $(VENV_STAMP) $(SITE_COPY_STAMP) $(SITE_ICON) $(SITE_DEVICE_OVERLAYS) $(SITE_SETTINGS) $(SITE_DEVICES) $(SITE_SCREENSHOTS)
	$(Q)echo " [ $(call LOG_TAG,site) ]"
	touch "$@"

site: $(SITE_EXPORT_STAMP) # build publishable site
	$(Q)echo " [ $(call LOG_TAG,site) ]"
.PHONY: s site

site_update: # fetch the latest site UI and rebuild the site
	$(Q)$(MAKE) SITE_UI_REFRESH=1 site
.PHONY: site_update

store: $(STORE_ICONS) $(STORE_HERO) $(STORE_VARIANTS) $(STORE_SCREENSHOTS) # generate store assets
	$(Q)echo " [ $(call LOG_TAG,store) ]"
.PHONY: store

t test: $(RESOURCES) $(VENV_STAMP) $(RELEASE_MANIFEST) # run test
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

smoke: $(VENV_STAMP) $(RELEASE_MANIFEST) # run smoke test
	$(Q)echo " [ $(call LOG_TAG,smoke) ]"
	$(Q)$(VENV_PYTHON) scripts/smoke --mode release
.PHONY: smoke

smoke_test: $(VENV_STAMP) $(RELEASE_MANIFEST) # run smoke test w/ tests
	$(Q)echo " [ $(call LOG_TAG,smoke_test) ]"
	$(Q)$(VENV_PYTHON) scripts/smoke --mode test
.PHONY: smoke_test

T all_tests: # run all automated release checks, stopping on failure
	$(Q)$(MAKE) lint
	$(Q)$(MAKE) test
	$(Q)$(MAKE) smoke_test
	$(Q)$(MAKE) smoke
.PHONY: all_tests

ifneq ($(MODE),release)
d deploy:
	$(Q)echo " [ $(call LOG_TAG,deploy) ]"
	$(Q)$(MAKE) NAME=$(NAME) DEVICE=$(DEVICE) MODE=release CHANNEL=$(CHANNEL) deploy
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
		$(RESOURCES_DIR)fonts/mip/generated     \
		$(RESOURCES_DIR)fonts/amoled/generated  \
		$(SITE_SETTINGS) $(SITE_DEVICES) $(SITE_DIR)settings-data.js $(SITE_DIR)devices-data.js \
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
	awk '
	/iq:product id="/ {
		device = $$0;
		sub(/^.*iq:product id="/, "", device);
		sub(/".*$$/, "", device);
		devices[++count] = device;
		if (length(device) > max_length) max_length = length(device);
	}
	END {
		middle = int((count + 1) / 2);
		for (i = 1; i <= middle; i++) {
			right = (i + middle <= count) ? devices[i + middle] : "";
			printf "     %-*s     %s\n", max_length, devices[i], right;
		}
	}' $(MANIFEST_TEMPLATE)
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
	# ---- channels ----
	printf " %bChannels%b\n" "$$B" "$$N"
	awk -v description_column=$(HELP_DESCRIPTION_COLUMN) '\
	/^[[:space:]]*CHANNEL_DESCRIPTION\.[[:alnum:]_-]+[[:space:]]*:=/ { \
		split($$1, name_parts, "."); \
		++n; \
		channels[n] = name_parts[2]; \
		descriptions[n] = substr($$0, index($$0, ":=") + 2); \
		sub(/^[[:space:]]*/, "", descriptions[n]); \
		if (length(channels[n]) > max_channel) max_channel = length(channels[n]); \
	} \
	END { \
		description_width = description_column - 6; \
		if (max_channel > description_width) \
			description_width = max_channel; \
		for (i = 1; i <= n; i++) \
			printf "     %-" description_width "s %s\n", channels[i], descriptions[i]; \
	}' $(MAKEFILE_LIST)
	printf "\n"
.PHONY: help
.PHONY: help
