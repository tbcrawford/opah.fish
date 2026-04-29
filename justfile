set shell := ["fish", "-c"]

# Default: show available recipes
default:
    @just --list

# ── Testing ────────────────────────────────────────────────────────────────────

# Run all verification tasks
check: fmt lint test

# Format all Fish source files
fmt:
    #!/usr/bin/env fish
    for f in functions/*.fish completions/*.fish conf.d/*.fish tests/*.fish
        fish_indent --write $f
    end

# Run tests, or one module/file when a target is provided
test target='':
    #!/usr/bin/env fish
    if test -z "{{target}}"
        set failed 0
        for file in tests/test_*.fish
            fishtape $file
            or set failed 1
        end
        exit $failed
    end

    set target "{{target}}"

    if string match -qr '(^tests/.*\.fish$|\.fish$)' -- $target
        fishtape $target
        exit $status
    end

    fishtape tests/test_$target.fish

# ── Installation ───────────────────────────────────────────────────────────────

# Install the plugin, or install test dependencies when a target is provided
install target='':
    #!/usr/bin/env fish
    if test -z "{{target}}"
        fisher install .
        exit $status
    end

    switch "{{target}}"
        case test
            fisher install jorgebucaran/fishtape
        case '*'
            echo "unknown install target: {{target}}" >&2
            exit 1
    end

# Uninstall the plugin from the local Fish environment
uninstall:
    fisher remove .

# ── Linting / Validation ───────────────────────────────────────────────────────

# Check syntax and formatting on all Fish source files
lint:
    #!/usr/bin/env fish
    set errors 0
    for f in functions/*.fish completions/*.fish conf.d/*.fish tests/*.fish
        if not fish --no-execute $f 2>/dev/null
            echo "syntax error: $f"
            set errors (math $errors + 1)
        end
        if not fish_indent $f | diff -q - $f >/dev/null 2>&1
            echo "indent error: $f"
            set errors (math $errors + 1)
        end
    end
    if test $errors -gt 0
        echo "$errors error(s) found"
        exit 1
    else
        echo "All files OK"
    end

# ── Development helpers ────────────────────────────────────────────────────────

# List public plugin functions
list:
    @fish -c 'for f in functions/_opah_*.fish functions/opah.fish; echo (path basename $f .fish); end'

# Show the active opah config file location
config:
    fish -c '_opah_find_config; and cat (_opah_find_config)'

# Clear the local opah cache
clean:
    fish -c 'source functions/_opah_get_cache_file.fish; and rm -f (_opah_get_cache_file)'
    @echo "Cache cleared"

# Show the current opah cache contents
cache:
    #!/usr/bin/env fish
    source functions/_opah_get_cache_file.fish
    set cache (_opah_get_cache_file)
    if test -f $cache
        cat $cache
    else
        echo "No cache file found at $cache"
    end
