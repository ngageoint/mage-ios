SHELL := /bin/zsh
.DEFAULT_GOAL := build-and-run

WORKSPACE ?= MAGE.xcworkspace
SCHEME ?= MAGE
SIM_NAME ?= iPhone 17
SIM_OS ?= 26.2
DESTINATION ?= platform=iOS Simulator,name=$(SIM_NAME),OS=$(SIM_OS)
DERIVED_DATA ?= build/DerivedData
RESULT_BUNDLE_BASE ?= build/TestResults
RESULT_STAMP ?= $(shell date +%Y%m%d-%H%M%S)
RESULT_BUNDLE ?= $(RESULT_BUNDLE_BASE)-$(RESULT_STAMP).xcresult
XCODEBUILD ?= xcodebuild
TOOLS_PATH ?= /opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
SIMCTL ?= xcrun simctl
APP_NAME ?= MAGE
APP_BUNDLE_ID ?= mil.nga.mage
APP_PATH ?= $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/$(APP_NAME).app
SIM_DEVICE_UDID ?= $(shell xcrun simctl list devices "iOS $(SIM_OS)" available | awk -v device="$(SIM_NAME)" -F '[()]' '{name=$$1; gsub(/^[[:space:]]+|[[:space:]]+$$/, "", name); if (name == device) {print $$2; exit}}')
TEST_TARGETS ?=
TEST_TARGET_BUNDLE ?= MAGETests

.PHONY: help bootstrap check-tools list build test run build-and-run clean

check-tools:
	@command -v xcbeautify >/dev/null || { \
		echo "Missing required tool: xcbeautify"; \
		echo "Install with: make bootstrap"; \
		echo "Or run: brew install xcbeautify"; \
		exit 1; \
	}

bootstrap:
	@command -v brew >/dev/null || { \
		echo "Homebrew is required to install xcbeautify."; \
		echo "Install Homebrew from: https://brew.sh"; \
		exit 1; \
	}
	@brew list xcbeautify >/dev/null 2>&1 || brew install xcbeautify
	@echo "xcbeautify ready: $$(command -v xcbeautify)"

help:
	@echo "make bootstrap # Install required local tool(s), currently xcbeautify"
	@echo "make check-tools # Verify required local tool(s) are installed"
	@echo "make list   # Show workspace schemes"
	@echo "make build  # Build MAGE for $(SIM_NAME) simulator (iOS $(SIM_OS))"
	@echo "make test   # Run targeted tests only; requires TEST_TARGETS, unique xcresult"
	@echo "            # Pass TEST_TARGETS='TestClass testMethod'"
	@echo "            # Multiple targets: separate entries with commas"
	@echo "            # Example: make test TEST_TARGETS='FilteredObservationsOverlayIdentityTests'"
	@echo "            # Example: make test TEST_TARGETS='MAGETests/FilteredObservationsOverlayIdentityTests/testLocalPolygonRedrawKeepsSingleOverlay'"
	@echo "            # Example: make test TEST_TARGETS='FilteredObservationsOverlayIdentityTests testLocalPolygonRedrawKeepsSingleOverlay,OtherTestClass'"
	@echo "make run    # Install and launch built app on a matching simulator"
	@echo "make build-and-run # Build, install, and launch app"
	@echo "make clean  # Clean derived data"

list: check-tools
	@set -o pipefail && \
	PATH='$(TOOLS_PATH):$$PATH' $(XCODEBUILD) -list -workspace $(WORKSPACE) | xcbeautify

build: check-tools
	@mkdir -p build
	@set -o pipefail && \
	PATH='$(TOOLS_PATH):$$PATH' $(XCODEBUILD) \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO \
		build | xcbeautify

test: check-tools
	@mkdir -p build
	@set -o pipefail && \
	setopt extendedglob && \
	if [[ -z "$(strip $(TEST_TARGETS))" ]]; then \
		echo "TEST_TARGETS is required."; \
		echo "Example: make test TEST_TARGETS='FilteredObservationsOverlayIdentityTests'"; \
		echo "Example: make test TEST_TARGETS='MAGETests/FilteredObservationsOverlayIdentityTests/testLocalPolygonRedrawKeepsSingleOverlay'"; \
		exit 1; \
	fi && \
	normalize_test_target() { \
		local target="$$1"; \
		target="$${target##[[:space:]]#}"; \
		target="$${target%%[[:space:]]#}"; \
		if [[ -z "$$target" ]]; then \
			return; \
		fi; \
		if [[ "$$target" == */* ]]; then \
			print -- "$$target"; \
		elif [[ "$$target" == *" "* ]]; then \
			local class_name="$${target%% *}"; \
			local test_name="$${target#* }"; \
			print -- "$(TEST_TARGET_BUNDLE)/$$class_name/$$test_name"; \
		else \
			print -- "$(TEST_TARGET_BUNDLE)/$$target"; \
		fi; \
	} && \
	only_testing_args=() && \
	raw_targets='$(TEST_TARGETS)' && \
	targets=($${(@s:,:)raw_targets}) && \
	for target in "$${targets[@]}"; do \
		normalized_target="$$(normalize_test_target "$$target")" && \
		if [[ -n "$$normalized_target" ]]; then \
			only_testing_args+=("-only-testing:$$normalized_target"); \
		fi; \
	done && \
	PATH='$(TOOLS_PATH):$$PATH' $(XCODEBUILD) \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		-resultBundlePath $(RESULT_BUNDLE) \
		"$${only_testing_args[@]}" \
		CODE_SIGNING_ALLOWED=NO \
		test | xcbeautify

run:
	@if [ ! -d "$(APP_PATH)" ]; then \
		echo "Built app not found at $(APP_PATH)"; \
		echo "Run 'make build' first or use 'make build-and-run'."; \
		exit 1; \
	fi
	@if [ -z "$(SIM_DEVICE_UDID)" ]; then \
		echo "No available simulator found for $(SIM_NAME) on iOS $(SIM_OS)."; \
		echo "Run: xcrun simctl list devices available"; \
		exit 1; \
	fi
	@open -a Simulator
	@$(SIMCTL) boot "$(SIM_DEVICE_UDID)" >/dev/null 2>&1 || true
	@$(SIMCTL) bootstatus "$(SIM_DEVICE_UDID)" -b >/dev/null
	@$(SIMCTL) install "$(SIM_DEVICE_UDID)" "$(APP_PATH)"
	@$(SIMCTL) launch "$(SIM_DEVICE_UDID)" "$(APP_BUNDLE_ID)"

build-and-run: build run

clean:
	@/bin/rm -rf build
