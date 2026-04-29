# Smoke test for running the CLI through Fish autoload.
#
# This catches regressions where helpers are moved into shared files but callers
# rely on autoloading individual helper names.
#
# Uses --no-config and a tmpdir so no live config, cache, or op calls are made.

set repo_root (path dirname (status dirname))
set tmp (mktemp -d)
set config_file "$tmp/secrets.yaml"
set cache_dir "$tmp/cache/opah"
set cache_file "$cache_dir/secrets.fish"
set runner_file "$tmp/autoload-runner.fish"

printf "secrets:\n  AUTOLOAD_TEST_KEY: op://Vault/Item/field\n" >"$config_file"

set -l functions_dir_esc (string escape --style=script -- "$repo_root/functions")
set -l config_esc (string escape --style=script -- "$config_file")
set -l cache_dir_esc (string escape --style=script -- "$cache_dir")
set -l cache_file_esc (string escape --style=script -- "$cache_file")

# Build a runner script that sets up isolated paths and a mock op, then invokes
# opah doctor — the same pattern used by test_cli_smoke.fish.
printf '%s\n' \
    "set -g fish_function_path $functions_dir_esc \$fish_function_path" \
    "function _opah_get_config_paths; echo $config_esc; end" \
    "function _opah_get_cache_dir; echo $cache_dir_esc; end" \
    "function _opah_get_cache_file; echo $cache_file_esc; end" \
    'function op' \
    '    switch "$argv[1]"' \
    '        case --version' \
    '            echo "2.0.0-mock"' \
    '            return 0' \
    '        case account' \
    '            switch "$argv[2]"' \
    '                case list' \
    '                    if contains -- --format=json $argv' \
    '                        printf '"'"'[{"email":"test@example.com"}]\n'"'"'' \
    '                    end' \
    '                    return 0' \
    '            end' \
    '        case read' \
    '            echo "mock_value"' \
    '            return 0' \
    '    end' \
    '    return 1' \
    end \
    '_opah_ui' \
    'opah doctor' >"$runner_file"

@test "cli autoload: opah doctor does not emit unknown command errors" \
    (begin
        set -l output (fish --no-config "$runner_file" 2>&1 | string collect)
        count (string match -a '*Unknown command*' -- $output)
    end) -eq 0

rm -rf $tmp
