function _secrets_show_help -d "Show main help text"
    # Load shared constants
    _secrets_constants

    # Function-specific icons
    set -l HELP_ICON "📖"

    printf "$SECRETS_CYAN$SECRETS_BOLD$SECRETS_LOCK_ICON 1Password Secrets Management CLI For Fish$SECRETS_RESET\n\n"

    printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
    printf "    secrets <SUBCOMMAND> [OPTIONS]\n\n"

    printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "SUBCOMMANDS:"
    printf "$SECRETS_GREEN    clear$SECRETS_RESET      Clear cached secrets and environment variables\n"
    printf "$SECRETS_GREEN    config$SECRETS_RESET     Show configuration file information and validate format\n"
    printf "$SECRETS_GREEN    doctor$SECRETS_RESET     Diagnose and validate complete setup\n"
    printf "$SECRETS_GREEN    refresh$SECRETS_RESET    Refresh secrets from 1Password (with auto-login prompting)\n"
    printf "$SECRETS_GREEN    reinit$SECRETS_RESET     Re-initialize plugin (useful after authentication changes)\n"
    printf "$SECRETS_GREEN    status$SECRETS_RESET     Show status of cached secrets and configuration\n"
    printf "$SECRETS_GREEN    help$SECRETS_RESET       Show this help message\n\n"

    printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
    printf "$SECRETS_DIM    secrets clear                # Clear all cached secrets$SECRETS_RESET\n"
    printf "$SECRETS_DIM    secrets config               # Show configuration file info$SECRETS_RESET\n"
    printf "$SECRETS_DIM    secrets doctor               # Run comprehensive diagnostics$SECRETS_RESET\n"
    printf "$SECRETS_DIM    secrets refresh              # Refresh all secrets from 1Password$SECRETS_RESET\n"
    printf "$SECRETS_DIM    secrets refresh GITHUB_TOKEN # Refresh specific secret$SECRETS_RESET\n"
    printf "$SECRETS_DIM    secrets status               # Show all cached secrets status$SECRETS_RESET\n"
    printf "$SECRETS_DIM    secrets status API_KEY       # Show status for specific secret$SECRETS_RESET\n"

    printf "\nFor detailed help on a subcommand, use: secrets <SUBCOMMAND> --help$SECRETS_RESET\n"
end
