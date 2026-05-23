# Tests for configuration validation and op:// enforcement
#
# Run with: fishtape tests/test_config_validate.fish

source (status dirname)/../functions/_opah_perms.fish
source (status dirname)/../functions/_opah_cache_validate.fish
source (status dirname)/../functions/_opah_config_validate.fish

set tmp (mktemp -d)
set config_file "$tmp/secrets.yaml"

printf "secrets:\n  API_KEY: op://vault/item/key\n" >"$config_file"
chmod 600 "$config_file"

@test "config validate: accepts secure config file" \
    (_opah_config_validate "$config_file" >/dev/null 2>&1; echo $status) -eq 0

@test "config validate: rejects world-readable config" \
    (begin
        chmod 644 "$config_file"
        _opah_config_validate "$config_file" >/dev/null 2>&1
        echo $status
    end) -eq 1

@test "is_op_ref: accepts op:// reference" \
    (_opah_is_op_ref "op://vault/item/field"; echo $status) -eq 0

@test "is_op_ref: rejects postgres URL" \
    (_opah_is_op_ref "postgres://user:pass@host/db"; echo $status) -eq 1

rm -rf $tmp
