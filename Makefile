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

NAME_SUFFIX.optimized   := _optimized
FLAG_MONKEYC.optimized  :=
FLAG_SIMULATE.optimized :=

NAME_SUFFIX.release   := _release
FLAG_MONKEYC.release  := --release
FLAG_SIMULATE.release :=

Q.0 := @
Q.1 :=
Q   := $(Q.$(V))

# ---- variables ----

SDK_DIR   := $(shell cat "$(HOME)/.Garmin/ConnectIQ/current-sdk.cfg")
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
DOCS_SETTINGS       := docs/settings-data.js
DOCS_ICON           := docs/assets/icon.svg
DEVICE_OVERLAY_SRC  := $(HOME)/.Garmin/ConnectIQ/Devices/fr955/fr955.png
DOCS_DEVICE_OVERLAY_LIGHT := docs/assets/fr955-light.png
DOCS_DEVICE_OVERLAY_DARK  := docs/assets/fr955-dark.png
DOCS_DEVICE_OVERLAYS := $(DOCS_DEVICE_OVERLAY_LIGHT) $(DOCS_DEVICE_OVERLAY_DARK)

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

$(DOCS_SETTINGS): $(DOCS_SETTINGS_DEPS)
	$(Q)echo " [ $(@F) ]"
	scripts/generate_docs_settings \
		--build $(BUILD_DIR) \
		--resources $(RESOURCES_DIR) \
		--source $(SOURCE_DIR)

$(DOCS_ICON): $(ICON)
	$(Q)echo " [ $(@F) ]"
	mkdir -p $(@D)
	cp $< $@

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
.PHONY: b0 build_optimized

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
		$(FLAG_SIMULATE.$(MODE))

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
.PHONY: st simulate_test

r resources: $(RESOURCES) # generate resources
.PHONY: r resources

d docs: $(DOCS_SETTINGS) $(DOCS_ICON) $(DOCS_DEVICE_OVERLAYS) # generate product page data
.PHONY: d docs

t test: $(RESOURCES) # run test
	$(Q)echo " [ test ]"
	pytest
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
	printf " %bTargets%b\n" "$$B" "$$N"
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
	printf "\n"
	printf " %bArguments%b\n" "$$B" "$$N"
	printf "     NAME              (default: $(NAME))\n"
	printf "     DEVICE            (default: $(DEVICE))\n"
	printf "     MODE              (default: $(MODE))\n"
	printf "     V                 (default: $(V))\n"
	printf "\n"
	printf " %bDevices%b\n" "$$B" "$$N"
	sed -n 's/.*iq:product id="\(.*\)"\/>/     \1/p' ./manifest.xml
	printf "\n"
	printf " %bModes%b\n" "$$B" "$$N"
	printf "     debug\n"
	printf "     test\n"
	printf "     optmized\n"
	printf "     release\n"
	printf "\n"
.PHONY: help
