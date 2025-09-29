function _secrets_show_help -d "Show main help text"
    # Color and formatting constants
    set -l GREEN '\033[0;32m'
    set -l CYAN '\033[0;36m'
    set -l GRAY '\033[0;90m'
    set -l BOLD '\033[1m'
    set -l DIM '\033[2m'
    set -l RESET '\033[0m'

    # Unicode icons
    set -l HELP_ICON "📖"
    set -l LOCK_ICON "🔐"
    set -l ARROW "→"

    printf "$CYAN$BOLD$LOCK_ICON 1Password Secrets Management CLI$RESET\n\n"

    printf "$BOLD"USAGE:"$RESET\n"
    printf "    secrets <SUBCOMMAND> [OPTIONS]\n\n"

    printf "$BOLD"SUBCOMMANDS:"$RESET\n"
    printf "$GREEN    status$RESET     Show status of cached secrets and configuration\n"
    printf "$GREEN    refresh$RESET    Refresh secrets from 1Password (with auto-login prompting)\n"
    printf "$GREEN    clear$RESET      Clear cached secrets and environment variables\n"
    printf "$GREEN    config$RESET     Show configuration file information and validate format\n"
    printf "$GREEN    doctor$RESET     Diagnose and validate complete setup\n"
    printf "$GREEN    reinit$RESET     Re-initialize plugin (useful after authentication changes)\n"
    printf "$GREEN    help$RESET       Show this help message\n\n"

    printf "$BOLD"EXAMPLES:"$RESET\n"
    printf "$DIM    secrets status               # Show all cached secrets status$RESET\n"
    printf "$DIM    secrets status API_KEY       # Show status for specific secret$RESET\n"
    printf "$DIM    secrets refresh              # Refresh all secrets from 1Password$RESET\n"
    printf "$DIM    secrets refresh GITHUB_TOKEN # Refresh specific secret$RESET\n"
    printf "$DIM    secrets clear                # Clear all cached secrets$RESET\n"
    printf "$DIM    secrets config               # Show configuration file info$RESET\n"
    printf "$DIM    secrets doctor               # Run comprehensive diagnostics$RESET\n\n"

    printf "For detailed help on a subcommand, use: secrets <SUBCOMMAND> --help$RESET\n"
end
