#
# Re-initialize plugin after authentication changes
#
# Performs a complete re-initialization of the opah plugin by clearing the cache,
# verifying 1Password authentication (and prompting for sign-in if needed), and
# reloading all secrets from the configuration. This is useful after changing
# 1Password accounts or when authentication has expired.
#
# @param -h/--help Shows usage information and examples
# @return 0 on success, 1 if sign-in fails or secrets cannot be reloaded
#
function _opah_reinit -d "Re-initialize plugin after authentication changes"
    # Ensure UI functions are available
    if not functions -q _opah_ui
        source (status dirname)/_opah_ui.fish
    end
    
    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Re-initialize plugin after authentication changes\n\n"
        printf "%sUSAGE:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    opah reinit\n\n"
        printf "%sEXAMPLES:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "%s    opah reinit    # Clear cache and reload all secrets%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    # Clear existing cache and environment variables
    _opah_step "1" "Clearing existing cache and environment variables..."
    printf "\n"
    _opah_clear --quiet-footer

    # Force 1Password re-authentication check
    _opah_step "2" "Checking 1Password authentication..."
    if not op account list >/dev/null 2>&1
        printf "\n%s       Signing in to 1Password...%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        if not op signin
            _opah_error "Failed: Could not sign in to 1Password" >&2
            return 1
        end
    else
        printf "\n"
        _opah_success "Already signed in to 1Password"
    end

    # Reload secrets from configuration
    _opah_step "3" "Reloading secrets from configuration..."
    printf "\n"
    if _opah_load --force
        _opah_hint "opah status" "to verify loaded secrets"
    else
        _opah_error "Failed: Could not reinitialize secrets" >&2
        _opah_hint "opah doctor" "to diagnose issues" >&2
        return 1
    end
end
