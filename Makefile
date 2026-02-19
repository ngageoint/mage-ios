SHELL := /bin/zsh
.DEFAULT_GOAL := build-and-run

WORKSPACE ?= MAGE.xcworkspace
SCHEME ?= MAGE
DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro,OS=latest
DERIVED_DATA ?= build/DerivedData
RESULT_BUNDLE_BASE ?= build/TestResults
RESULT_STAMP ?= $(shell date +%Y%m%d-%H%M%S)
RESULT_BUNDLE ?= $(RESULT_BUNDLE_BASE)-$(RESULT_STAMP).xcresult
MIGRATION_RESULT_BUNDLE ?= $(RESULT_BUNDLE_BASE)-migration-$(RESULT_STAMP).xcresult
XCODEBUILD ?= xcodebuild
TOOLS_PATH ?= /opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
SIMCTL ?= xcrun simctl
APP_NAME ?= MAGE
APP_BUNDLE_ID ?= mil.nga.mage
APP_PATH ?= $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/$(APP_NAME).app
TEST_TARGET ?= MAGETests/ObservationToObservationPolicyTests
MIGRATION_TEST_TARGET ?= MAGETests/ObservationToObservationPolicyTests

.PHONY: help list build test test-migration run build-and-run clean check-tools bootstrap

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
	@echo "make build  # Build MAGE for iPhone 17 Pro simulator"
	@echo "make test   # Run targeted tests only (default: $(TEST_TARGET), unique xcresult)"
	@echo "            # Override: make test TEST_TARGET=MAGETests/SomeTestCase"
	@echo "make test-migration # Run migration-focused tests only (unique xcresult)"
	@echo "                   # Target: $(MIGRATION_TEST_TARGET)"
	@echo "make run    # Install and launch built app on booted simulator"
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
		PATH='$(TOOLS_PATH):$$PATH' $(XCODEBUILD) \
			-workspace $(WORKSPACE) \
			-scheme $(SCHEME) \
			-destination '$(DESTINATION)' \
			-derivedDataPath $(DERIVED_DATA) \
			-resultBundlePath $(RESULT_BUNDLE) \
		-only-testing:$(TEST_TARGET) \
		CODE_SIGNING_ALLOWED=NO \
		test | xcbeautify

test-migration: check-tools
	@mkdir -p build
	@set -o pipefail && \
		PATH='$(TOOLS_PATH):$$PATH' $(XCODEBUILD) \
			-workspace $(WORKSPACE) \
			-scheme $(SCHEME) \
			-destination '$(DESTINATION)' \
			-derivedDataPath $(DERIVED_DATA) \
			-resultBundlePath $(MIGRATION_RESULT_BUNDLE) \
			-only-testing:$(MIGRATION_TEST_TARGET) \
			-skip-testing:MAGEGeoPackageTests \
			CODE_SIGNING_ALLOWED=NO \
			test | xcbeautify

run:
	@if [ ! -d "$(APP_PATH)" ]; then \
		echo "Built app not found at $(APP_PATH)"; \
		echo "Run 'make build' first or use 'make build-and-run'."; \
		exit 1; \
	fi
	@open -a Simulator
	@$(SIMCTL) bootstatus booted -b >/dev/null
	@$(SIMCTL) install booted "$(APP_PATH)"
	@$(SIMCTL) launch booted "$(APP_BUNDLE_ID)"

build-and-run: build run

clean:
	@/bin/rm -rf build
