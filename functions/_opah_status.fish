#
# Show status of cached secrets and configuration
#
# Displays the current status of cached secrets including cache file location,
# last update time, and a list of all cached secrets. Can show status for all
# secrets or a specific secret. Indicates whether each secret is cached and
# loaded into the environment.
#
# @param SECRET_NAME Optional secret name to show status for only that secret
# @param -h/--help Shows usage information and examples
# @return 0 always succeeds
#
function _opah_status -d "Show status of cached secrets and configuration"
    # Initialize UI functions
    if not functions -q _opah_init_ui
        source (status dirname)/_opah_init_ui.fish
    end
    _opah_init_ui
    
    argparse 'h/help' -- $argv

    set -l specific_key $argv[1]
    
    # Ensure path utilities are available
    if not functions -q _opah_get_cache_file
        source (status dirname)/_opah_paths.fish
    end
    
    set -l cache_file (_opah_get_cache_file)

    if set -q _flag_help
        printf "Show status of cached secrets and configuration\n\n"
        printf "%sUSAGE:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    opah status [SECRET_NAME]\n\n"
        printf "%sARGUMENTS:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    SECRET_NAME    Show status for specific secret (optional)\n\n"
        printf "%sEXAMPLES:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "%s    opah status              # Show all opah status%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "%s    opah status API_KEY      # Show status for API_KEY only%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    # Check cache file existence
    if test -f "$cache_file"
        _opah_file "Cache file: $(_opah_dim $cache_file)"
        _opah_info "Last updated: $(_opah_dim "$(stat -f '%Sm' "$cache_file")")"
        
        # Check cache file permissions
        set -l cache_perms (stat -f "%A" "$cache_file" 2>/dev/null || echo "unknown")
        if test "$cache_perms" = "600"
            _opah_info "Permissions: $(_opah_dim "Secure (600)")"
        else
            _opah_warning "Permissions: $cache_perms (should be 600)"
        end

        # Count cached secrets
        set -l secret_count (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "\n"
        _opah_info "Cached secrets: $secret_count"

        if test -n "$specific_key"
            printf "\n"
            # Show specific secret status
            if grep -q "^set -gx $specific_key " "$cache_file"
                _opah_success "Secret '$(_opah_bold $specific_key)': Cached"
                if set -q $specific_key
                    _opah_success "Environment: Loaded"
                else
                    _opah_error "Environment: Not loaded"
                end
            else
                _opah_error "Secret '$(_opah_bold $specific_key)': Not found in cache"
            end
        else
            printf "\n"
            # Show all secrets
            printf "%sCached secrets:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
            grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
                set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
                if set -q $key
                    printf "    %s%s:%s %s✓%s Cached & Loaded\n" $__OPAH_COLOR_DIM "$key" $__OPAH_COLOR_RESET $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
                else
                    printf "    %s%s:%s %s✓%s Cached, %s✗%s Not loaded\n" $__OPAH_COLOR_DIM "$key" $__OPAH_COLOR_RESET $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
                end
            end
        end
    else
        _opah_error "Cache file: Not found"
        _opah_hint "opah refresh" "to create cache"
    end
end