# Regression tests for the repository justfile.

set repo_root (path dirname (status dirname))
set justfile_path "$repo_root/justfile"

function run_just
    fish -c "cd $repo_root; just $argv" 2>&1 | string collect
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
        set -l output (fish -c "cd $repo_root; just --dry-run test cache" 2>&1 | string collect)
        string match -q '*fishtape tests/test_$target.fish*' -- $output
        echo $status
    end) -eq 0

@test "justfile: test recipe accepts an explicit test file path" \
    (begin
        set -l output (fish -c "cd $repo_root; just --dry-run test tests/test_paths.fish" 2>&1 | string collect)
        string match -q '*fishtape $target*' -- $output
        echo $status
    end) -eq 0

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

@test "justfile: exposes fmt recipe" \
    (begin
        set -l output (run_just --list)
        string match -q '* fmt *' -- $output
        echo $status
    end) -eq 0
