function _secrets_show_help -d "Show main help text"
    printf "%s🔐 1Password Secrets Management CLI%s\n\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET

    printf "%sUSAGE:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
    printf "    secrets <SUBCOMMAND> [OPTIONS]\n\n"

    printf "%sSUBCOMMANDS:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
    printf "    clear      Clear cached secrets and environment variables\n"
    printf "    config     Show configuration file information and validate format\n"
    printf "    doctor     Diagnose and validate complete setup\n"
    printf "    refresh    Refresh secrets from 1Password\n"
    printf "    reinit     Re-initialize plugin after authentication changes\n"
    printf "    status     Show status of cached secrets and configuration\n"
    printf "    help       Show this help message\n\n"

    printf "%sEXAMPLES:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
    printf "%s    secrets status               # Show all cached secrets status%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
    printf "%s    secrets refresh              # Refresh all secrets from 1Password%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
    printf "%s    secrets clear                # Clear all cached secrets%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
    printf "%s    secrets doctor               # Run comprehensive diagnostics%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET

    printf "\nFor detailed help on a subcommand, use: secrets <SUBCOMMAND> --help\n"
end
