set shell := ["fish", "-c"]

# Default: show available recipes
default:
    @just --list

# ── Testing ────────────────────────────────────────────────────────────────────

# Run the full test suite
test:
    #!/usr/bin/env fish
    set failed 0
    for file in tests/test_*.fish
        fishtape $file
        or set failed 1
    end
    exit $failed

# Run a single test file  (e.g. `just test-one tests/test_cache.fish`)
test-one file:
    fishtape {{ file }}

# Run tests for a specific module by name  (e.g. `just test-module cache`)
test-module name:
    fishtape tests/test_{{ name }}.fish

# ── Installation ───────────────────────────────────────────────────────────────

# Install fishtape test runner via Fisher
install-fishtape:
    fisher install jorgebucaran/fishtape

# Install the plugin locally for manual testing
install-local:
    fisher install .

# Uninstall the plugin from the local Fish environment
uninstall:
    fisher remove .

# ── Linting / Validation ───────────────────────────────────────────────────────

# Check syntax on all Fish source files
lint:
    #!/usr/bin/env fish
    set errors 0
    for f in functions/*.fish completions/*.fish conf.d/*.fish tests/*.fish
        if not fish --no-execute $f 2>/dev/null
            echo "syntax error: $f"
            set errors (math $errors + 1)
        end
    end
    if test $errors -gt 0
        echo "$errors file(s) have syntax errors"
        exit 1
    else
        echo "All files OK"
    end

# ── Development helpers ────────────────────────────────────────────────────────

# List all public functions defined by this plugin
functions:
    @fish -c 'for f in functions/_opah_*.fish functions/opah.fish; echo (path basename $f .fish); end'

# Print the active opah config file location (requires plugin loaded)
config:
    fish -c '_opah_find_config; and cat (_opah_find_config)'

# Clear the local opah secret cache
clear-cache:
    fish -c 'source functions/_opah_paths.fish; and rm -f (_opah_get_cache_file)'
    @echo "Cache cleared"

# Show the contents of the secret cache (for debugging — values are plaintext!)
show-cache:
    #!/usr/bin/env fish
    source functions/_opah_paths.fish
    set cache (_opah_get_cache_file)
    if test -f $cache
        cat $cache
    else
        echo "No cache file found at $cache"
    end

# ── CI helpers ─────────────────────────────────────────────────────────────────

# Run everything CI would run: lint + tests
ci: lint test
