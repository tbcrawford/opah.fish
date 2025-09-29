function _secrets_refresh -d "Refresh secrets from 1Password"
    # Color and formatting constants
    set -l GREEN '\033[0;32m'
    set -l CYAN '\033[0;36m'
    set -l YELLOW '\033[0;33m'
    set -l GRAY '\033[0;90m'
    set -l BOLD '\033[1m'
    set -l DIM '\033[2m'
    set -l RESET '\033[0m'

    # Unicode icons
    set -l INFO_ICON ℹ
    set -l REFRESH_ICON "🔄"
    set -l KEY_ICON "🔑"

    set -l specific_key $argv[1]

    if test "$argv[1]" = --help
        printf "Refresh secrets from 1Password (with auto-login prompting)\n\n"
        printf "$BOLD"USAGE:"$RESET\n"
        printf "    secrets refresh [SECRET_NAME]\n\n"
        printf "$BOLD"ARGUMENTS:"$RESET\n"
        printf "    SECRET_NAME    Refresh specific secret only (optional)\n\n"
        printf "$BOLD"EXAMPLES:"$RESET\n"
        printf "$DIM    secrets refresh              # Refresh all secrets$RESET\n"
        printf "$DIM    secrets refresh DATABASE_URL # Refresh DATABASE_URL only$RESET\n"
        return 0
    end

    if test -n "$specific_key"
        printf "$YELLOW$KEY_ICON$RESET Refreshing specific secret: $BOLD%s$RESET\n" "$specific_key"
        _secrets_load --key="$specific_key"
    else
        printf "$CYAN$REFRESH_ICON$RESET Refreshing all secrets from 1Password...\n"
        _secrets_load --force
    end
end
