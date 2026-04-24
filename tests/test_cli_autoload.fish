# Smoke test for running the CLI through Fish autoload.
#
# This catches regressions where helpers are moved into shared files but callers
# rely on autoloading individual helper names.

set repo_root (path dirname (status dirname))

@test "cli autoload: opah doctor does not emit unknown command errors" \
    (begin
        set -l output (fish -C "set -g fish_function_path $repo_root/functions \$fish_function_path" -c 'opah doctor' 2>&1 | string collect)
        count (string match -a '*Unknown command*' -- $output)
    end) -eq 0
