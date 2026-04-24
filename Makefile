.PHONY: test test-install help

## Run the full test suite (requires fishtape)
test:
	@if not fish -c "functions -q fishtape" 2>/dev/null; then \
		echo "fishtape not installed. Run: fisher install jorgebucaran/fishtape"; \
		exit 1; \
	fi
	fishtape tests/test_*.fish

## Install fishtape test runner via Fisher
test-install:
	fisher install jorgebucaran/fishtape

## Run a single test file (usage: make test-one FILE=tests/test_cache.fish)
test-one:
	fishtape $(FILE)

help:
	@grep -E '^##' Makefile | sed 's/## //'
