# Smoke tests for running the CLI through Fish autoload only.
#
# Catches regressions where helpers live in shared files but callers rely on
# autoloading individual function names (the Fisher install path).
#
# Uses --no-config and a tmpdir so no live config, cache, or op calls are made.

set repo_root (path dirname (status dirname))
set tmp (mktemp -d)
set config_file "$tmp/secrets.yaml"
set cache_dir "$tmp/cache/opah"
set cache_file "$cache_dir/secrets.fish"
set doctor_runner "$tmp/autoload-doctor.fish"
set refresh_runner "$tmp/autoload-refresh.fish"

printf "secrets:\n  AUTOLOAD_TEST_KEY: op://Vault/Item/field\n" >"$config_file"
chmod 600 "$config_file"

set -g __opah_test_functions_dir_esc (string escape --style=script -- "$repo_root/functions")
set -g __opah_test_config_esc (string escape --style=script -- "$config_file")
set -g __opah_test_cache_dir_esc (string escape --style=script -- "$cache_dir")
set -g __opah_test_cache_file_esc (string escape --style=script -- "$cache_file")

function __opah_write_autoload_runner -a runner_path command_body
    printf '%s\n' \
        "set -g fish_function_path $__opah_test_functions_dir_esc \$fish_function_path" \
        "function _opah_get_config_paths; echo $__opah_test_config_esc; end" \
        "function _opah_find_config; echo $__opah_test_config_esc; end" \
        "function _opah_get_cache_dir; echo $__opah_test_cache_dir_esc; end" \
        "function _opah_get_cache_file; echo $__opah_test_cache_file_esc; end" \
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
        "$command_body" >"$runner_path"
end

__opah_write_autoload_runner "$doctor_runner" 'opah doctor'
__opah_write_autoload_runner "$refresh_runner" 'opah refresh >/dev/null'

@test "cli autoload: opah doctor does not emit unknown command errors" \
    (begin
        set -l output (fish --no-config "$doctor_runner" 2>&1 | string collect)
        count (string match -a '*Unknown command*' -- $output)
    end) -eq 0

@test "cli autoload: opah refresh does not emit unknown command errors" \
    (begin
        set -l output (fish --no-config "$refresh_runner" 2>&1 | string collect)
        count (string match -a '*Unknown command*' -- $output)
    end) -eq 0

@test "cli autoload: opah refresh exits successfully with mocked op" \
    (fish --no-config "$refresh_runner" >/dev/null 2>&1; echo $status) -eq 0

rm -rf $tmp
set -e __opah_test_functions_dir_esc __opah_test_config_esc __opah_test_cache_dir_esc __opah_test_cache_file_esc
