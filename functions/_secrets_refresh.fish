function _secrets_refresh -d "Refresh secrets from 1Password"
    argparse 'h/help' -- $argv

    # Load shared constants
    _secrets_constants

    set -l specific_key $argv[1]

    if set -q _flag_help
        printf "Refresh secrets from 1Password (with auto-login prompting)\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
        printf "    secrets refresh [SECRET_NAME]\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "ARGUMENTS:"
        printf "    SECRET_NAME    Refresh specific secret only (optional)\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
        printf "$SECRETS_DIM    secrets refresh              # Refresh all secrets$SECRETS_RESET\n"
        printf "$SECRETS_DIM    secrets refresh DATABASE_URL # Refresh DATABASE_URL only$SECRETS_RESET\n"
        return 0
    end

    if test -n "$specific_key"
        printf "🔑 Refreshing specific secret: $SECRETS_BOLD%s$SECRETS_RESET\n" "$specific_key"
        _secrets_load --key="$specific_key"
    else
        printf "🔄 Refreshing all secrets from 1Password...\n"
        _secrets_load --force
    end
end
