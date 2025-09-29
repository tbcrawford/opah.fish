function _secrets_show_help -d "Show main help text"
    # Function-specific icons
    set -l HELP_ICON "📖"

    printf "%s🔐 1Password Secrets Management CLI For Fish%s\n\n" (set_color --bold) (set_color normal)

    printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
    printf "    secrets <SUBCOMMAND> [OPTIONS]\n\n"

    printf "%s%s%s\n" (set_color --bold) "SUBCOMMANDS:" (set_color normal)
    printf "%s    clear%s      Clear cached secrets and environment variables\n" (set_color green) (set_color normal)
    printf "%s    config%s     Show configuration file information and validate format\n" (set_color green) (set_color normal)
    printf "%s    doctor%s     Diagnose and validate complete setup\n" (set_color green) (set_color normal)
    printf "%s    refresh%s    Refresh secrets from 1Password (with auto-login prompting)\n" (set_color green) (set_color normal)
    printf "%s    reinit%s     Re-initialize plugin (useful after authentication changes)\n" (set_color green) (set_color normal)
    printf "%s    status%s     Show status of cached secrets and configuration\n" (set_color green) (set_color normal)
    printf "%s    help%s       Show this help message\n\n" (set_color green) (set_color normal)

    printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
    printf "%s    secrets clear                # Clear all cached secrets%s\n" (set_color --dim) (set_color normal)
    printf "%s    secrets config               # Show configuration file info%s\n" (set_color --dim) (set_color normal)
    printf "%s    secrets doctor               # Run comprehensive diagnostics%s\n" (set_color --dim) (set_color normal)
    printf "%s    secrets refresh              # Refresh all secrets from 1Password%s\n" (set_color --dim) (set_color normal)
    printf "%s    secrets refresh GITHUB_TOKEN # Refresh specific secret%s\n" (set_color --dim) (set_color normal)
    printf "%s    secrets status               # Show all cached secrets status%s\n" (set_color --dim) (set_color normal)
    printf "%s    secrets status API_KEY       # Show status for specific secret%s\n" (set_color --dim) (set_color normal)

    printf "\nFor detailed help on a subcommand, use: secrets <SUBCOMMAND> --help%s\n" (set_color normal)
end
