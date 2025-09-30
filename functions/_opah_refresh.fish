#
# Refresh secrets from 1Password
#
# Forces a refresh of secrets from 1Password, bypassing the cache. Can refresh
# all secrets or a specific secret by name. This is useful when secrets have
# been updated in 1Password and need to be synchronized to the local environment.
#
# @param SECRET_NAME Optional secret name to refresh only that specific secret
# @param -h/--help Shows usage information and examples
# @return 0 on success, non-zero on failure
#
function _opah_refresh -d "Refresh secrets from 1Password"
    # Ensure UI functions are available
    if not functions -q _opah_ui
        source (status dirname)/_opah_ui.fish
    end
    
    argparse 'h/help' -- $argv

    set -l specific_key $argv[1]

    if set -q _flag_help
        printf "Refresh secrets from 1Password\n\n"
        printf "%sUSAGE:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    opah refresh [SECRET_NAME]\n\n"
        printf "%sARGUMENTS:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    SECRET_NAME    Refresh specific secret only (optional)\n\n"
        printf "%sEXAMPLES:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "%s    opah refresh              # Refresh all secrets%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "%s    opah refresh DATABASE_URL # Refresh DATABASE_URL only%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    if test -n "$specific_key"
        _opah_security "Refreshing specific secret: $(_opah_bold $specific_key)"
        _opah_load --key="$specific_key"
    else
        _opah_load --force
    end
end
