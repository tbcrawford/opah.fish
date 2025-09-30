function _secrets_refresh -d "Refresh secrets from 1Password"
    # Ensure UI functions are available
    if not functions -q _secrets_ui
        source (status dirname)/_secrets_ui.fish
    end
    
    argparse 'h/help' -- $argv

    set -l specific_key $argv[1]

    if set -q _flag_help
        printf "Refresh secrets from 1Password\n\n"
        printf "%sUSAGE:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "    secrets refresh [SECRET_NAME]\n\n"
        printf "%sARGUMENTS:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "    SECRET_NAME    Refresh specific secret only (optional)\n\n"
        printf "%sEXAMPLES:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "%s    secrets refresh              # Refresh all secrets%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        printf "%s    secrets refresh DATABASE_URL # Refresh DATABASE_URL only%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        return 0
    end

    if test -n "$specific_key"
        _secrets_security "Refreshing specific secret: $(_secrets_bold $specific_key)"
        _secrets_load --key="$specific_key"
    else
        _secrets_load --force
    end
end
