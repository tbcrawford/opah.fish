# End-to-end CLI smoke tests using a mocked `op` function.
#
# These tests exercise the real `opah` CLI entrypoint in isolated Fish
# subprocesses without touching a real 1Password vault, user config, or cache.

set repo_root (path dirname (status dirname))
set tmp (mktemp -d)
set config_file "$tmp/secrets.yaml"
set cache_dir "$tmp/cache/opah"
set cache_file "$cache_dir/secrets.fish"
set runner_file "$tmp/mock-cli-runner.fish"
set functions_dir "$repo_root/functions"

printf '%s\n' \
    'secrets:' \
    '  API_KEY: op://Vault/Item/api_key' \
    '  DATABASE_URL: op://Vault/Item/db_url' >"$config_file"
chmod 600 "$config_file"

function write_mock_runner -a script_body
    set -l functions_dir_escaped (string escape --style=script -- "$functions_dir")
    set -l config_file_escaped (string escape --style=script -- "$config_file")
    set -l cache_dir_escaped (string escape --style=script -- "$cache_dir")
    set -l cache_file_escaped (string escape --style=script -- "$cache_file")

    printf '%s\n' \
        "set -g fish_function_path $functions_dir_escaped \$fish_function_path" \
        'function op' \
        '    switch "$argv[1]"' \
        '        case --version' \
        '            echo "2.34.0-mock"' \
        '            return 0' \
        '        case account' \
        '            switch "$argv[2]"' \
        '                case list' \
        '                    if contains -- --format=json $argv' \
        '                        printf ''[{"email":"ci@example.com","url":"example.1password.com"}]\n''' \
        '                    else' \
        '                        echo "ci@example.com"' \
        '                    end' \
        '                    return 0' \
        '            end' \
        '        case signin' \
        '            echo "mock sign-in"' \
        '            return 0' \
        '        case read' \
        '            switch "$argv[-1]"' \
        '                case "op://Vault/Item/api_key"' \
        '                    echo "mock-api-key"' \
        '                case "op://Vault/Item/db_url"' \
        '                    echo "postgres://mock-db"' \
        '                case "*"' \
        '                    echo "mocked-value-for-$argv[-1]"' \
        '            end' \
        '            return 0' \
        '    end' \
        '    return 1' \
        end \
        "function _opah_get_config_paths; echo $config_file_escaped; end" \
        "function _opah_get_cache_dir; echo $cache_dir_escaped; end" \
        "function _opah_get_cache_file; echo $cache_file_escaped; end" \
        "$script_body" >"$runner_file"

    echo "$runner_file"
end

function run_mocked_cli -a script_body
    fish --no-config (write_mock_runner "$script_body") 2>&1
end

function run_mocked_cli_status -a script_body
    fish --no-config (write_mock_runner "$script_body") >/dev/null 2>&1
    echo $status
end

function reset_cache
    rm -rf "$cache_dir"
end

function assert_refresh_writes_cache
    reset_cache
    set -l refresh_status (run_mocked_cli_status 'opah refresh >/dev/null')
    if test "$refresh_status" -ne 0; or not test -f "$cache_file"
        return
    end
    run_mocked_cli 'opah clear >/dev/null' >/dev/null 2>&1
    if not test -f "$cache_file"
        echo ok
    end
end

function assert_status_ok
    reset_cache
    set -l cli_status (run_mocked_cli_status 'opah refresh >/dev/null; and opah status API_KEY >/dev/null')
    if test "$cli_status" -eq 0
        echo ok
    end
end

@test "cli smoke: bare opah shows help" \
    (begin
        set -l output (run_mocked_cli 'opah')
        if string match -q '*Usage*' -- $output; and string match -q '*Commands*' -- $output
            echo ok
        end
    end) = ok

@test "cli smoke: opah help shows help without unknown commands" \
    (begin
        set -l output (run_mocked_cli 'opah help')
        if string match -q '*unknown command*' -- $output
            echo bad
        else if string match -q '*Commands*' -- $output
            echo ok
        end
    end) = ok

@test "cli smoke: opah config validates temp config" \
    (begin
        set -l output (run_mocked_cli 'opah config')
        if string match -q '*Configuration valid*' -- $output; and string match -q "*$config_file*" -- $output
            echo ok
        end
    end) = ok

@test "cli smoke: refresh creates cache file" \
    (begin
        assert_refresh_writes_cache
    end) = ok

@test "cli smoke: opah status reports mocked secret as cached and loaded" \
    (begin
        assert_status_ok
    end) = ok

@test "cli smoke: opah clear removes mocked cache" \
    (begin
        reset_cache
        set -l output (run_mocked_cli 'opah refresh >/dev/null; and opah clear; and if test -f (_opah_get_cache_file); echo cache-present; else echo cache-missing; end')
        if string match -q '*Secrets cleared*' -- $output; and string match -q '*cache-missing*' -- $output
            echo ok
        end
    end) = ok

@test "cli smoke: opah doctor succeeds against mocked environment" \
    (begin
        reset_cache
        set -l output (run_mocked_cli 'opah refresh >/dev/null; and opah doctor; and echo doctor-ok' | string collect)
        if string match -q '*doctor-ok*' -- $output; and string match -q '*All systems operational*' -- $output
            echo ok
        end
    end) = ok

@test "cli smoke: opah reinit reloads mocked secrets" (begin; reset_cache; run_mocked_cli_status 'opah reinit >/dev/null'; end) -eq 0

@test "cli smoke: all mocked subcommands exit successfully" (begin; reset_cache; run_mocked_cli_status 'opah help >/dev/null; and opah config >/dev/null; and opah refresh >/dev/null; and opah clear >/dev/null; and opah doctor >/dev/null'; end) -eq 0

@test "conf.d: non-interactive shell loads secrets from cache into environment" \
    (begin
        reset_cache
        run_mocked_cli 'opah refresh' >/dev/null 2>&1
        fish --no-config (write_mock_runner "source $repo_root/conf.d/opah.fish >/dev/null 2>&1; echo \$API_KEY") 2>/dev/null
    end) = mock-api-key

@test "conf.d: OPAH_AUTOLOAD=0 skips loading in non-interactive shell" \
    (begin
        reset_cache
        run_mocked_cli 'opah refresh' >/dev/null 2>&1
        fish --no-config (write_mock_runner "set -gx OPAH_AUTOLOAD 0; source $repo_root/conf.d/opah.fish >/dev/null 2>&1; if set -q API_KEY; echo loaded; else echo skipped; end") 2>/dev/null
    end) = skipped

rm -rf "$tmp"
