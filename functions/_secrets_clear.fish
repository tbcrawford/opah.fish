function _secrets_clear -d "Clear cached secrets and environment variables"
    # Load shared constants
    _secrets_constants

    argparse 'h/help' 'q/quiet-footer' -- $argv

    if set -q _flag_help
        printf "Clear cached secrets and environment variables\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
        printf "    secrets clear [OPTIONS]\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "OPTIONS:"
        printf "    -h, --help            Show this help message\n"
        printf "    -q, --quiet-footer    Skip the footer help message\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
        printf "$SECRETS_DIM    secrets clear                # Clear all cached secrets and unset environment variables$SECRETS_RESET\n"
        printf "$SECRETS_DIM    secrets clear --quiet-footer # Clear secrets without showing footer hint$SECRETS_RESET\n"
        return 0
    end

    set -l cache_file "$__fish_cache_dir/1password-secrets/secrets.fish"
    set -l cleared_count 0

    printf "🗑️$SECRETS_RESET Clearing cached secrets...\n"

    # Unset environment variables first
    if test -f "$cache_file"
        printf "$SECRETS_DIM  - Unsetting environment variables...$SECRETS_RESET\n"
        grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
            set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
            if set -q $key
                set -e $key
                set cleared_count (math $cleared_count + 1)
                printf "$SECRETS_DIM    $SECRETS_ARROW$SECRETS_RESET Unset: $SECRETS_BOLD%s$SECRETS_RESET\n" "$key"
            end
        end

        # Remove cache file
        printf "\n$SECRETS_DIM  - Removing cache file...$SECRETS_RESET\n"
        rm -f "$cache_file"
        printf "    $SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET Cache file removed: $SECRETS_DIM%s$SECRETS_RESET\n" "$cache_file"
    else
        printf "$SECRETS_GRAY$SECRETS_INFO_ICON $SECRETS_RESET No cache file found at: $SECRETS_DIM%s$SECRETS_RESET\n" "$cache_file"
    end

    printf "\n$SECRETS_GREEN$SECRETS_BOLD$SECRETS_CHECK_MARK Success!$SECRETS_RESET Secrets cleared\n"

    # Footer hint (skip if called with --quiet-footer flag)
    if not set -q _flag_quiet_footer
        printf "\n$SECRETS_DIM"
        printf "Run 'secrets refresh' to reload secrets from 1Password$SECRETS_RESET\n"
    end
end
