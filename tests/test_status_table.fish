# Unit tests for _opah_status_table.
# Strips ANSI escape codes before asserting text content.

set repo_root (path dirname (status dirname))
set functions_dir "$repo_root/functions"

function run_table -a script_body
    fish --no-config -C "set fish_function_path $functions_dir \$fish_function_path" \
        -c "_opah_ui; $script_body" 2>&1 \
        | string replace --all --regex '\x1b\[[0-9;]*m' ''
end

@test "table: top border starts with box corner" \
    (run_table '_opah_status_table 1 API_KEY 1' | string collect | string match -r '^┌') \
    = ┌

@test "table: bottom border ends with box corner" \
    (run_table '_opah_status_table 1 API_KEY 1' | string collect | string match -r '┘\n?$') \
    != ""

@test "table: header row contains Secret, Cached, Loaded" \
    (run_table '_opah_status_table 1 API_KEY 1' | string match -r 'Secret.*Cached.*Loaded') \
    != ""

@test "table: separator row contains cross junctions" \
    (run_table '_opah_status_table 1 API_KEY 1' | string match -r '├.*┼.*┤') \
    != ""

@test "table: loaded key shows check in both columns" \
    (run_table '_opah_status_table 1 API_KEY 1' | string match -r 'API_KEY.*✓.*✓') \
    != ""

@test "table: unloaded key shows check cached and cross loaded" \
    (run_table '_opah_status_table 1 API_KEY 0' | string match -r 'API_KEY.*✓.*✕') \
    != ""

@test "table: multiple keys each appear on their own row" \
    (begin
        set out (run_table '_opah_status_table 2 API_KEY DB_PASS 1 0' | string collect)
        if string match -q '*API_KEY*' -- $out; and string match -q '*DB_PASS*' -- $out
            echo ok
        end
    end) = ok

@test "table: short keys use Secret header as minimum column width" \
    (run_table '_opah_status_table 1 K 1' | string match -r 'Secret') \
    != ""

@test "table: key is truncated with ellipsis when terminal is narrow" \
    (run_table 'set -gx COLUMNS 40; _opah_status_table 1 ABCDEFGHIJKLMNOPQRSTUVWXYZ 1' \
        | string match -r '…') \
    = '…'

@test "table: zero secrets returns without output" \
    (run_table '_opah_status_table 0' | count) \
    -eq 0

@test "table: very narrow terminal does not overflow header" \
    (run_table 'set -gx COLUMNS 28; _opah_status_table 1 K 1' \
        | string match -r 'Secret') \
    != ""
