#
# Show configuration file information and validate format.
#
function _opah_config -d "Show configuration file information and validate format"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section Usage
        printf "  %sopah config%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        _opah_section Examples
        printf "  %sopah config    # show config file info and validate format%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    # ── Locations ────────────────────────────────────────────────────────────
    _opah_section Locations
    set -l secret_paths (_opah_get_config_paths)
    for path in $secret_paths
        if test -f "$path"
            _opah_success "$path"
        else
            _opah_error "$path"
        end
    end

    # Find active config
    set -l config_file (_opah_find_config)
    if test $status -ne 0
        _opah_error "No configuration file found"
        _opah_hint "create: ~/.config/fish/secrets.yaml"
        _opah_hint "format: secrets:\n  API_KEY: \"op://vault/item/field\""
        return 1
    end

    _opah_info "Active config: $config_file"
    set -l mod_time (command stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$config_file" 2>/dev/null; or command stat -c "%y" "$config_file" 2>/dev/null | string replace -r '\.[0-9]+ .*' '')
    _opah_info "Last modified: $mod_time"

    # ── Validation ───────────────────────────────────────────────────────────
    _opah_section Validation

    if not _opah_parse_yaml "$config_file" >/dev/null 2>&1
        _opah_error "No 'secrets:' section found in configuration"
        return 1
    end

    set -l config_count 0
    _opah_parse_yaml "$config_file" | while read -l key value
        set config_count (math $config_count + 1)
        if string match -q "op://*" "$value"
            _opah_success "$key: $value"
        else
            _opah_warning "$key: $value"
        end
    end

    # ── Summary ──────────────────────────────────────────────────────────────
    _opah_section Summary
    _opah_success "Configuration valid" "$config_count secret(s) defined"
end
