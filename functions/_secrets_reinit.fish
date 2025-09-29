function _secrets_reinit -d "Re-initialize plugin (useful after authentication changes)"
    # Load shared constants
    _secrets_constants

    argparse 'h/help' -- $argv

    # Local icons specific to reinit function
    set -l RESTART_ICON "🔄"
    set -l STEP_ICON "📍"

    if set -q _flag_help
        printf "Re-initialize plugin (useful after authentication changes)\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
        printf "    secrets reinit\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
        printf "$SECRETS_DIM    secrets reinit    # Clear cache and reload all secrets$SECRETS_RESET\n"
        return 0
    end

    # Clear existing cache and environment variables
    echo ""
    echo "📍 Step 1: Clearing existing cache and environment variables..."
    echo ""
    _secrets_clear --quiet-footer
    echo ""

    # Force 1Password re-authentication check
    echo "📍 Step 2: Checking 1Password authentication..."
    if not op account list >/dev/null 2>&1
        printf "$SECRETS_DIM   Signing in to 1Password...$SECRETS_RESET\n"
        if not op signin
            printf "$SECRETS_RED$SECRETS_BOLD$SECRETS_CROSS_MARK Failed: $SECRETS_RESET Could not sign in to 1Password\n" >&2
            return 1
        end
    else
        printf "\n$SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET Already signed in to 1Password\n"
    end

    # Reload secrets from configuration
    echo ""
    echo "📍 Step 3: Reloading secrets from configuration..."
    echo ""
    if _secrets_load --force
        printf "\n$SECRETS_DIM"
        printf "Run 'secrets status' to verify loaded secrets$SECRETS_RESET\n"
    else
        printf "\n$SECRETS_RED$SECRETS_BOLD$SECRETS_CROSS_MARK Failed:$SECRETS_RESET Could not reinitialize secrets\n" >&2
        printf "$SECRETS_DIM" >&2
        printf "Run 'secrets doctor' to diagnose issues$SECRETS_RESET\n" >&2
        return 1
    end
end
