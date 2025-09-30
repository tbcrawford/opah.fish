#
# Show main help text
#
# Displays the main help text for the opah CLI including usage information,
# available subcommands, and examples. This is the default help screen shown
# when running 'opah help' or 'opah' without arguments.
#
# @return 0 always succeeds
#
function _opah_show_help -d "Show main help text"
    printf "%s🐠 Fishy 1Password Secrets Management CLI%s\n\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET

    printf "%sUSAGE:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
    printf "    opah <SUBCOMMAND> [OPTIONS]\n\n"

    printf "%sSUBCOMMANDS:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
    printf "    clear      Clear cached secrets and environment variables\n"
    printf "    config     Show configuration file information and validate format\n"
    printf "    doctor     Diagnose and validate complete setup\n"
    printf "    refresh    Refresh secrets from 1Password\n"
    printf "    reinit     Re-initialize plugin after authentication changes\n"
    printf "    status     Show status of cached secrets and configuration\n"
    printf "    help       Show this help message\n\n"

    printf "%sEXAMPLES:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
    printf "%s    opah status               # Show all cached opah status%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "%s    opah refresh              # Refresh all secrets from 1Password%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "%s    opah clear                # Clear all cached secrets%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "%s    opah doctor               # Run comprehensive diagnostics%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET

    printf "\nFor detailed help on a subcommand, use: opah <SUBCOMMAND> --help\n"
end
