# Justfile Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the `justfile` into a smaller single-word task interface with argument-driven `test` and `install` recipes.

**Architecture:** Keep the redesign entirely inside `justfile` and verify behavior through a new Fish-based regression test file that checks recipe names and invocation semantics. Consolidate old helpers into a few verbs while preserving the useful capabilities behind argument dispatch.

**Tech Stack:** Fish shell, `just`, `fishtape`

---

## File Structure

- Modify: `justfile`
  - Replace the current recipe surface with the approved single-word command shape.
- Create: `tests/test_justfile.fish`
  - Add regression tests that assert recipe names and key dispatch behavior.

## Task 1: Add Justfile Regression Tests

**Files:**
- Create: `tests/test_justfile.fish`

- [ ] **Step 1: Write the failing test file for the new recipe surface**

Create `tests/test_justfile.fish` with this content:

```fish
# Regression tests for the repository justfile.

set repo_root (path dirname (status dirname))
set justfile_path "$repo_root/justfile"

function run_just -a args
    fish -c "cd $repo_root; just $args" 2>&1 | string collect
end

@test "justfile: exposes check recipe" \
    (begin
        set -l output (run_just --list)
        string match -q '* check *' -- $output
        echo $status
    end) -eq 0

@test "justfile: exposes single test recipe" \
    (begin
        set -l output (run_just --list)
        string match -q '* test *' -- $output
        echo $status
    end) -eq 0

@test "justfile: does not expose test-one recipe" \
    (begin
        set -l output (run_just --list)
        count (string match -a '*test-one*' -- $output)
    end) -eq 0

@test "justfile: does not expose test-module recipe" \
    (begin
        set -l output (run_just --list)
        count (string match -a '*test-module*' -- $output)
    end) -eq 0

@test "justfile: test recipe accepts a module name" \
    (begin
        set -l output (run_just test cache)
        string match -q '*cache_write:*' -- $output
        echo $status
    end) -eq 0

@test "justfile: test recipe accepts an explicit test file path" \
    (begin
        set -l output (run_just test tests/test_paths.fish)
        string match -q '*get_cache_dir:*' -- $output
        echo $status
    end) -eq 0
```

- [ ] **Step 2: Run the new justfile regression test to verify it fails**

Run:

```bash
just test tests/test_justfile.fish
```

Expected:

```text
not ok 1 justfile: exposes check recipe
```

- [ ] **Step 3: Confirm the failure is due to the current recipe surface, not a bad test**

Run:

```bash
just --list
```

Expected:

```text
test-one
test-module
```

and no `check` recipe.

- [ ] **Step 4: Commit the failing justfile regression test**

Run:

```bash
git add tests/test_justfile.fish
git commit -m "test: add justfile regression coverage"
```

## Task 2: Implement The New Test And Check Recipes

**Files:**
- Modify: `justfile`
- Test: `tests/test_justfile.fish`

- [ ] **Step 1: Replace the old test-related recipes with `check` and argument-driven `test`**

Update the testing section of `justfile` to this shape:

```just
set shell := ["fish", "-c"]

# Default: show available tasks
default:
    @just --list

# Run all verification tasks
check: lint test

# Run tests, or one module/file when a target is provided
test target=''
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
```

This step intentionally removes:

- `test-one`
- `test-module`
- `ci`

and replaces them with:

- `test [target]`
- `check`

- [ ] **Step 2: Run the justfile regression test to verify it now passes the new surface checks**

Run:

```bash
just test tests/test_justfile.fish
```

Expected:

```text
ok 1 justfile: exposes check recipe
ok 2 justfile: exposes single test recipe
ok 3 justfile: does not expose test-one recipe
ok 4 justfile: does not expose test-module recipe
ok 5 justfile: test recipe accepts a module name
ok 6 justfile: test recipe accepts an explicit test file path
```

- [ ] **Step 3: Verify the consolidated commands work directly**

Run:

```bash
just test cache
just test tests/test_load.fish
just check
```

Expected:

```text
# ok
```

for each invocation.

- [ ] **Step 4: Commit the new testing interface**

Run:

```bash
git add justfile
git commit -m "build: simplify test tasks in justfile"
```

## Task 3: Implement The New Install And Utility Recipe Surface

**Files:**
- Modify: `justfile`
- Test: `tests/test_justfile.fish`

- [ ] **Step 1: Extend the justfile regression test with utility surface checks**

Append these tests to `tests/test_justfile.fish`:

```fish
@test "justfile: exposes single install recipe" \
    (begin
        set -l output (run_just --list)
        string match -q '* install *' -- $output
        echo $status
    end) -eq 0

@test "justfile: does not expose install-fishtape recipe" \
    (begin
        set -l output (run_just --list)
        count (string match -a '*install-fishtape*' -- $output)
    end) -eq 0

@test "justfile: does not expose install-local recipe" \
    (begin
        set -l output (run_just --list)
        count (string match -a '*install-local*' -- $output)
    end) -eq 0

@test "justfile: exposes list recipe instead of functions" \
    (begin
        set -l output (run_just --list)
        string match -q '* list *' -- $output
        and test (count (string match -a '* functions *' -- $output)) -eq 0
        echo $status
    end) -eq 0

@test "justfile: exposes clean and cache recipes" \
    (begin
        set -l output (run_just --list)
        string match -q '* clean *' -- $output
        and string match -q '* cache *' -- $output
        echo $status
    end) -eq 0
```

- [ ] **Step 2: Run the justfile regression test to verify the new utility expectations fail**

Run:

```bash
just test tests/test_justfile.fish
```

Expected:

```text
not ok 7 justfile: exposes single install recipe
```

- [ ] **Step 3: Replace the old helper recipes with the approved single-word surface**

Update the non-test portion of `justfile` so it has this shape:

```just
# Install the plugin, or install test dependencies when a target is provided
install target=''
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

# List public plugin functions
list:
    @fish -c 'for f in functions/_opah_*.fish functions/opah.fish; echo (path basename $f .fish); end'

# Show the active opah config file location
config:
    fish -c '_opah_find_config; and cat (_opah_find_config)'

# Clear the local opah cache
clean:
    fish -c 'source functions/_opah_paths.fish; and rm -f (_opah_get_cache_file)'
    @echo "Cache cleared"

# Show the current opah cache contents
cache:
    #!/usr/bin/env fish
    source functions/_opah_paths.fish
    set cache (_opah_get_cache_file)
    if test -f $cache
        cat $cache
    else
        echo "No cache file found at $cache"
    end
```

This step removes:

- `install-fishtape`
- `install-local`
- `functions`
- `clear-cache`
- `show-cache`

and replaces them with:

- `install [target]`
- `list`
- `clean`
- `cache`

- [ ] **Step 4: Run the justfile regression test and command listing again**

Run:

```bash
just test tests/test_justfile.fish
just --list
```

Expected:

```text
# ok
```

and a simplified top-level list containing only single-word recipe names.

- [ ] **Step 5: Commit the utility surface redesign**

Run:

```bash
git add justfile tests/test_justfile.fish
git commit -m "build: simplify justfile utility tasks"
```

## Task 4: Final Verification And Output Review

**Files:**
- Modify: `justfile` (only if verification reveals a concrete issue)
- Modify: `tests/test_justfile.fish` (only if verification reveals a concrete issue)

- [ ] **Step 1: Run the justfile regression suite in isolation**

Run:

```bash
just test tests/test_justfile.fish
```

Expected:

```text
# ok
```

- [ ] **Step 2: Run the project verification through the redesigned command surface**

Run:

```bash
just check
```

Expected:

```text
All files OK
...
# ok
```

- [ ] **Step 3: Inspect the final task surface manually**

Run:

```bash
just --list
```

Expected recipes:

```text
cache
check
clean
config
default
install
lint
list
test
uninstall
```

No recipe name should contain a dash, underscore, or mixed-case word.

- [ ] **Step 4: Inspect the justfile diff before handoff**

Run:

```bash
git diff -- justfile tests/test_justfile.fish
```

Expected:

```text
diff --git a/justfile b/justfile
diff --git a/tests/test_justfile.fish b/tests/test_justfile.fish
```

- [ ] **Step 5: Create the final integration commit**

Run:

```bash
git add justfile tests/test_justfile.fish
git commit -m "build: redesign justfile task surface"
```

## Spec Coverage Check

- Single-word recipe names: covered in Tasks 2, 3, and 4.
- Consolidated `test [target]`: covered in Tasks 1 and 2.
- Consolidated `install [target]`: covered in Task 3.
- `check` replacing `ci`: covered in Task 2.
- `clean` and `cache` replacing cache-specific helpers: covered in Task 3.
- Removal of old punctuated recipe names: covered in Tasks 2, 3, and 4.
- Simpler `just --list` output: covered in Task 4.

## Self-Review Notes

- No placeholders remain.
- File paths are exact.
- Commands and expected outputs are concrete.
- The plan stays within the approved command shape and does not introduce extra helper scripts or additional recipe naming styles.
