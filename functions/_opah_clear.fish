#
# Clear cached secrets and environment variables.
#
# Flags:
#   --quiet    suppress final summary and hint (used internally by opah reinit)
#
function _opah_clear -d "Clear cached secrets and environment variables"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section Usage
        printf "  %sopah clear%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        _opah_section Examples
        printf "  %sopah clear    # clear all cached secrets and env vars%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l quiet 0
    if contains -- --quiet $argv
        set quiet 1
    end

    set -l cache_file (_opah_get_cache_file)

    # Unset environment variables (tab-separated cache or legacy set -gx format)
    set -l keys
    if test -f "$cache_file"
        set -l is_legacy false
        while read -l line
            string match -qr '^\s*(#|$)' -- "$line"; and continue
            if string match -qr '^set -gx ' -- "$line"
                set is_legacy true
            end
            break
        end <"$cache_file"

        if test "$is_legacy" = true
            set -a keys (string match -ra "set -gx ([A-Za-z_][A-Za-z0-9_]*)" <"$cache_file" | string replace -ra 'set -gx ([A-Za-z_][A-Za-z0-9_]*).*' '$1')
        else
            set -a keys (_opah_cache_keys "$cache_file")
        end
    end

    set -l config_file (_opah_find_config 2>/dev/null)
    if test -n "$config_file"
        for line in (_opah_parse_yaml "$config_file")
            set -l parts (string split -m 1 \t "$line")
            if test (count $parts) -ge 1
                set -a keys $parts[1]
            end
        end
    end

    for key in (printf '%s\n' $keys | sort -u)
        if set -q $key
            set -e $key 2>/dev/null
            _opah_info "Unset $key"
        end
    end

    # Remove cache file
    if test -f "$cache_file"
        rm -f "$cache_file"
        _opah_success "Cache file removed"
    else
        _opah_info "No cache file found"
    end

    if test $quiet -eq 0
        _opah_success "Secrets cleared"
        _opah_hint "run: opah refresh to reload secrets from 1Password"
    end
end
