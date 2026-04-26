#
# Diagnose and validate the complete opah setup.
#
function _opah_doctor -d "Diagnose and validate complete setup"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section Usage
        printf "  %sopah doctor%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        _opah_section Examples
        printf "  %sopah doctor    # run comprehensive diagnostics%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l issues 0

    # ── 1Password CLI ────────────────────────────────────────────────────────
    _opah_section "1Password CLI"
    if command -q op
        set -l op_version (op --version 2>/dev/null)
        _opah_success "op is installed" "version $op_version"
    else
        _opah_error "op is not installed"
        _opah_hint "install from: https://developer.1password.com/docs/cli/get-started/"
        set issues (math $issues + 1)
    end

    # ── Authentication ───────────────────────────────────────────────────────
    _opah_section Authentication
    if command -q op
        set -l accounts (op account list --format=json 2>/dev/null)
        if test -n "$accounts"; and test "$accounts" != "[]"
            _opah_success "Signed in to 1password"
            set -l emails (echo $accounts | string match -ra '"email":"[^"]*"' | string replace -ra '"email":"([^"]*)"' '$1' | string join ", ")
            if test -n "$emails"
                printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$emails" $__OPAH_COLOR_RESET
            end
        else
            _opah_warning "Not signed in to 1password"
            _opah_hint "run: op signin"
        end
    else
        _opah_info "Skipped (op not installed)"
    end

    # ── Configuration ────────────────────────────────────────────────────────
    _opah_section Configuration
    set -l config_file (_opah_find_config)
    if test -n "$config_file"
        _opah_success "$config_file"
        set -l secret_count (string match -ra "op://" <"$config_file" | count)
        _opah_info "$secret_count secrets defined"
        # Check for non-1Password values
        set -l non_op (grep -v "op://" "$config_file" | grep -v "secrets:" | grep -v '^#' | grep -v '^$' | grep ":" | count 2>/dev/null)
        if test "$non_op" -gt 0
            _opah_warning "$non_op value(s) are not 1password references"
            set issues (math $issues + 1)
        end
    else
        _opah_error "No configuration file found"
        _opah_hint "create: ~/.config/fish/secrets.yaml"
        set issues (math $issues + 1)
    end

    # ── Cache ────────────────────────────────────────────────────────────────
    _opah_section Cache
    set -l cache_file (_opah_get_cache_file)
    set -l cache_dir (_opah_get_cache_dir)
    if test -d "$cache_dir"
        _opah_success "Cache directory exists" "$cache_dir"
    else
        _opah_warning "Cache directory missing (created automatically on refresh)"
    end

    if test -f "$cache_file"
        set -l mod_time (command stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$cache_file" 2>/dev/null; or command stat -c "%y" "$cache_file" 2>/dev/null | string replace -r '\.[0-9]+ .*' '')
        set -l secret_count (_opah_cache_count "$cache_file")
        _opah_success "Cache file exists"
        printf "%s     Last updated: %s%s\n" $__OPAH_COLOR_DIM "$mod_time" $__OPAH_COLOR_RESET
        printf "%s     Cached secrets: %s%s\n" $__OPAH_COLOR_DIM "$secret_count" $__OPAH_COLOR_RESET
        set -l perms (command stat -f "%OLp" "$cache_file" 2>/dev/null; or command stat -c "%a" "$cache_file" 2>/dev/null)
        if test "$perms" = 600
            printf "%s     Permissions: secure (600)%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        else
            _opah_warning "Permissions $perms (should be 600)"
            _opah_hint "run: chmod 600 $cache_file"
            set issues (math $issues + 1)
        end
    else
        _opah_warning "Cache file missing"
        _opah_hint "run: opah refresh to create cache"
    end

    # ── Fish Shell Integration ───────────────────────────────────────────────
    _opah_section "Fish Shell Integration"
    if functions -q opah; and functions -q _opah_load
        _opah_success "Core functions are available"
    else
        _opah_error "Core functions not loaded"
        set issues (math $issues + 1)
    end

    # ── Summary ──────────────────────────────────────────────────────────────
    _opah_section Summary
    if test $issues -eq 0
        _opah_success "All systems operational"
        _opah_hint "run: opah status to verify loaded secrets"
    else
        _opah_warning "$issues issue(s) detected"
        _opah_hint "Address the items marked with ✕ or ▲ above"
    end
end
