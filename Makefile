PHONY: help cleanup build-ios-no-codesign

.DEFAULT_GOAL := help
BLUE := \033[34m
RESET := \033[0m

help: ## Show this help message
	@echo 'Usage:'
	@echo '  make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

cleanup: ## Clean up build artifacts and dependencies
	@echo "Cleaning up project..."
	@flutter clean
	@rm -rf pubspec.lock
	@rm -rf ios/.symlinks
	@rm -rf ios/Pods
	@rm -f ios/Podfile.lock
	@flutter pub get
	@echo "Cleanup complete"

build-ios-no-codesign: ## Build the iOS app without code signing
	@echo "Building iOS app without code signing..."
	@cd example && flutter build ios --no-codesign --config-only
	@echo "Build complete"