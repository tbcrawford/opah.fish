#
# Display status of cached secrets and configuration.
#
function _opah_status -d "Show status of cached secrets"
    # --help
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section Usage
        printf "  %sopah status%s %s[SECRET_NAME]%s\n" \
            $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        _opah_section Arguments
        printf "  %sSECRET_NAME%s  %sshow status for a specific secret (optional)%s\n" \
            $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        _opah_section Examples
        printf "  %sopah status              # show all cached secrets%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "  %sopah status API_KEY      # show status for API_KEY only%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l cache_file (_opah_get_cache_file)
    set -l filter_key $argv[1]

    if not test -f "$cache_file"
        _opah_error "cache file not found"
        _opah_hint "run: opah refresh to create cache"
        return 1
    end

    # Cache section
    _opah_section Cache
    set -l mod_time (command stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$cache_file" 2>/dev/null; or command stat -c "%y" "$cache_file" 2>/dev/null | string replace -r '\.[0-9]+ .*' '')
    _opah_info "last updated $mod_time"
    set -l perms (command stat -f "%OLp" "$cache_file" 2>/dev/null; or command stat -c "%a" "$cache_file" 2>/dev/null)
    if test "$perms" = 600
        _opah_info "permissions secure (600)"
    else
        _opah_warning "permissions $perms (should be 600)"
    end

    # Parse cached keys
    set -l cached_keys (_opah_cache_keys "$cache_file")

    # Secrets section
    _opah_section Secrets

    if test -n "$filter_key"
        # Single secret lookup
        if contains -- $filter_key $cached_keys
            set -l is_loaded 0
            if set -q $filter_key
                set is_loaded 1
            end
            _opah_status_table 1 $filter_key $is_loaded
        else
            _opah_error "$filter_key not found in cache"
            return 1
        end
    else
        # All secrets — build parallel loaded-flags list
        set -l loaded_count 0
        set -l loaded_flags
        for key in $cached_keys
            if set -q $key
                set -a loaded_flags 1
                set loaded_count (math $loaded_count + 1)
            else
                set -a loaded_flags 0
            end
        end
        _opah_status_table (count $cached_keys) $cached_keys $loaded_flags

        set -l total (count $cached_keys)

        # Summary section
        _opah_section Summary
        if test $loaded_count -eq $total
            _opah_success "$total of $total secrets loaded"
        else
            _opah_warning "$loaded_count of $total secrets loaded"
            _opah_hint "run: opah refresh to reload"
        end
    end
end
