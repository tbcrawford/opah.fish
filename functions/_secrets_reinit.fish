function _secrets_reinit -d "Re-initialize plugin (useful after authentication changes)"
    # Color and formatting constants
    set -l GREEN '\033[0;32m'
    set -l RED '\033[0;31m'
    set -l CYAN '\033[0;36m'
    set -l GRAY '\033[0;90m'
    set -l BOLD '\033[1m'
    set -l DIM '\033[2m'
    set -l RESET '\033[0m'

    # Unicode icons
    set -l CHECK_MARK "✓"
    set -l CROSS_MARK "✗"
    set -l INFO_ICON ℹ
    set -l RESTART_ICON "🔄"
    set -l STEP_ICON "📍"

    if test "$argv[1]" = --help
        printf "Re-initialize plugin (useful after authentication changes)\n\n"
        printf "$BOLD"USAGE:"$RESET\n"
        printf "    secrets reinit\n\n"
        printf "$BOLD"EXAMPLES:"$RESET\n"
        printf "$DIM    secrets reinit    # Clear cache and reload all secrets$RESET\n"
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
        printf "$DIM   Signing in to 1Password...$RESET\n"
        if not op signin
            printf "$RED$BOLD$CROSS_MARK Failed: $RESET Could not sign in to 1Password\n" >&2
            return 1
        end
    else
        printf "\n$GREEN$CHECK_MARK$RESET Already signed in to 1Password\n"
    end

    # Reload secrets from configuration
    echo ""
    echo "📍 Step 3: Reloading secrets from configuration..."
    echo ""
    if _secrets_load --force
        printf "\n$DIM"
        printf "Run 'secrets status' to verify loaded secrets$RESET\n"
    else
        printf "\n$RED$BOLD$CROSS_MARK Failed:$RESET Could not reinitialize secrets\n" >&2
        printf "$DIM" >&2
        printf "Run 'secrets doctor' to diagnose issues$RESET\n" >&2
        return 1
    end
end
