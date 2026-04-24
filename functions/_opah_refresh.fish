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
    argparse h/help -- $argv

    set -l specific_key $argv[1]

    if set -q _flag_help
        printf "Refresh secrets from 1Password\n\n"
        printf "%sUSAGE:%s\n" (set_color --bold) (set_color normal)
        printf "    opah refresh [SECRET_NAME]\n\n"
        printf "%sARGUMENTS:%s\n" (set_color --bold) (set_color normal)
        printf "    SECRET_NAME    Refresh specific secret only (optional)\n\n"
        printf "%sEXAMPLES:%s\n" (set_color --bold) (set_color normal)
        printf "%s    opah refresh              # Refresh all secrets%s\n" (set_color --dim) (set_color normal)
        printf "%s    opah refresh DATABASE_URL # Refresh DATABASE_URL only%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    if test -n "$specific_key"
        _opah_security "Refreshing specific secret: "(_opah_bold $specific_key)
        _opah_load --key="$specific_key"
    else
        _opah_load --force
    end
end
