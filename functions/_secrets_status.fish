function _secrets_status -d "Show status of cached secrets and configuration"
    # Ensure UI functions are available
    if not functions -q _secrets_ui
        source (status dirname)/_secrets_ui.fish
    end
    
    argparse 'h/help' -- $argv

    set -l specific_key $argv[1]
    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"

    if set -q _flag_help
        printf "Show status of cached secrets and configuration\n\n"
        printf "%sUSAGE:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "    secrets status [SECRET_NAME]\n\n"
        printf "%sARGUMENTS:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "    SECRET_NAME    Show status for specific secret (optional)\n\n"
        printf "%sEXAMPLES:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "%s    secrets status              # Show all secrets status%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        printf "%s    secrets status API_KEY      # Show status for API_KEY only%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        return 0
    end

    # Check cache file existence
    if test -f "$cache_file"
        _secrets_file "Cache file: $(_secrets_dim $cache_file)"
        _secrets_info "Last updated: $(_secrets_dim "$(stat -f '%Sm' "$cache_file")")"

        # Count cached secrets
        set -l secret_count (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "\n"
        _secrets_info "Cached secrets: $secret_count"

        if test -n "$specific_key"
            printf "\n"
            # Show specific secret status
            if grep -q "^set -gx $specific_key " "$cache_file"
                _secrets_success "Secret '$(_secrets_bold $specific_key)': Cached"
                if set -q $specific_key
                    _secrets_success "Environment: Loaded"
                else
                    _secrets_error "Environment: Not loaded"
                end
            else
                _secrets_error "Secret '$(_secrets_bold $specific_key)': Not found in cache"
            end
        else
            printf "\n"
            # Show all secrets
            printf "%sCached secrets:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
            grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
                set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
                if set -q $key
                    printf "    %s%s:%s %s✓%s Cached & Loaded\n" $__SECRETS_COLOR_DIM "$key" $__SECRETS_COLOR_RESET $__SECRETS_COLOR_SUCCESS $__SECRETS_COLOR_RESET
                else
                    printf "    %s%s:%s %s✓%s Cached, %s✗%s Not loaded\n" $__SECRETS_COLOR_DIM "$key" $__SECRETS_COLOR_RESET $__SECRETS_COLOR_SUCCESS $__SECRETS_COLOR_RESET $__SECRETS_COLOR_ERROR $__SECRETS_COLOR_RESET
                end
            end
        end
    else
        _secrets_error "Cache file: Not found"
        _secrets_hint "secrets refresh" "to create cache"
    end
end