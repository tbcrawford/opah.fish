function _secrets_reinit -d "Re-initialize plugin after authentication changes"
    # Ensure UI functions are available
    if not functions -q _secrets_ui
        source (status dirname)/_secrets_ui.fish
    end
    
    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Re-initialize plugin after authentication changes\n\n"
        printf "%sUSAGE:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "    secrets reinit\n\n"
        printf "%sEXAMPLES:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "%s    secrets reinit    # Clear cache and reload all secrets%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        return 0
    end

    # Clear existing cache and environment variables
    _secrets_step "1" "Clearing existing cache and environment variables..."
    printf "\n"
    _secrets_clear --quiet-footer

    # Force 1Password re-authentication check
    _secrets_step "2" "Checking 1Password authentication..."
    if not op account list >/dev/null 2>&1
        printf "\n%s       Signing in to 1Password...%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        if not op signin
            _secrets_error "Failed: Could not sign in to 1Password" >&2
            return 1
        end
    else
        printf "\n"
        _secrets_success "Already signed in to 1Password"
    end

    # Reload secrets from configuration
    _secrets_step "3" "Reloading secrets from configuration..."
    printf "\n"
    if _secrets_load --force
        _secrets_hint "secrets status" "to verify loaded secrets"
    else
        _secrets_error "Failed: Could not reinitialize secrets" >&2
        _secrets_hint "secrets doctor" "to diagnose issues" >&2
        return 1
    end
end
