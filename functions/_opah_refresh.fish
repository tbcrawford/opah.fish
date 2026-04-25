#
# Refresh secrets from 1Password.
#
function _opah_refresh -d "Refresh secrets from 1Password"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section "Usage"
        printf "  %sopah refresh%s %s[SECRET_NAME]%s\n" \
            $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        _opah_section "Arguments"
        printf "  %sSECRET_NAME%s  %srefresh specific secret only (optional)%s\n" \
            $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        _opah_section "Examples"
        printf "  %sopah refresh              # refresh all secrets%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "  %sopah refresh DATABASE_URL # refresh DATABASE_URL only%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l specific_key $argv[1]

    if test -n "$specific_key"
        _opah_info "refreshing secret: $specific_key"
        _opah_load --key="$specific_key"
    else
        _opah_load --force
    end
end
