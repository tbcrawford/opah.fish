function _secrets_refresh -d "Refresh secrets from 1Password"
    argparse 'h/help' -- $argv

    set -l specific_key $argv[1]

    if set -q _flag_help
        printf "Refresh secrets from 1Password (with auto-login prompting)\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    secrets refresh [SECRET_NAME]\n\n"
        printf "%s%s%s\n" (set_color --bold) "ARGUMENTS:" (set_color normal)
        printf "    SECRET_NAME    Refresh specific secret only (optional)\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    secrets refresh              # Refresh all secrets%s\n" (set_color --dim) (set_color normal)
        printf "%s    secrets refresh DATABASE_URL # Refresh DATABASE_URL only%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    if test -n "$specific_key"
        printf "🔑 Refreshing specific secret: %s%s%s\n" (set_color --bold) "$specific_key" (set_color normal)
        _secrets_load --key="$specific_key"
    else
        printf "🔄 Refreshing all secrets from 1Password...\n"
        _secrets_load --force
    end
end
