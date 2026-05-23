# Tests for _opah_autoload_enabled
#
# Run with: fishtape tests/test_autoload_enabled.fish

source (status dirname)/../functions/_opah_autoload_enabled.fish

@test "autoload: enabled by default when unset" \
    (begin; set -e OPAH_AUTOLOAD 2>/dev/null; _opah_autoload_enabled; echo $status; end) -eq 0

@test "autoload: 0 disables autoload" \
    (begin; set -gx OPAH_AUTOLOAD 0; _opah_autoload_enabled; echo $status; end) -eq 1

@test "autoload: False disables autoload" \
    (begin; set -gx OPAH_AUTOLOAD False; _opah_autoload_enabled; echo $status; end) -eq 1

@test "autoload: NO disables autoload" \
    (begin; set -gx OPAH_AUTOLOAD NO; _opah_autoload_enabled; echo $status; end) -eq 1

@test "autoload: 1 enables autoload" \
    (begin; set -gx OPAH_AUTOLOAD 1; _opah_autoload_enabled; echo $status; end) -eq 0
