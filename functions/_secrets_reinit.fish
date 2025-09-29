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

    printf "$CYAN$BOLD$RESTART_ICON Re-initializing 1Password Secrets Plugin$RESET\n"
    printf "$GRAY━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$RESET\n\n"

    # Clear existing cache and environment variables
    printf "$STEP_ICON $BOLD"Step 1:"$RESET Clearing existing cache and environment variables...\n"
    _secrets_clear
    printf "\n"

    # Force 1Password re-authentication check
    printf "$STEP_ICON $BOLD"Step 2:"$RESET Checking 1Password authentication...\n"
    if not op account list >/dev/null 2>&1
        printf "$DIM   Signing in to 1Password...$RESET\n"
        if not op signin
            printf "$RED$BOLD$CROSS_MARK Failed:$RESET Could not sign in to 1Password\n" >&2
            return 1
        end
    else
        printf "$GREEN$CHECK_MARK$RESET Already signed in to 1Password\n"
    end
    printf "\n"

    # Reload secrets from configuration
    printf "$STEP_ICON $BOLD"Step 3:"$RESET Reloading secrets from configuration...\n"
    if _load_secrets --force
        printf "$GREEN$BOLD$CHECK_MARK Success!$RESET Plugin reinitialized\n\n"
        printf "$GRAY   Run 'secrets status' to verify loaded secrets$RESET\n"
    else
        printf "$RED$BOLD$CROSS_MARK Failed:$RESET Could not reinitialize secrets\n" >&2
        printf "$GRAY   Run 'secrets doctor' to diagnose issues$RESET\n" >&2
        return 1
    end
end
