function _secrets_clear -d "Clear cached secrets and environment variables"
    argparse 'q/quiet-footer' -- $argv
    # Color and formatting constants
    set -l GREEN '\033[0;32m'
    set -l RED '\033[0;31m'
    set -l CYAN '\033[0;36m'
    set -l GRAY '\033[0;90m'
    set -l BOLD '\033[1m'
    set -l DIM '\033[2m'
    set -l RESET '\033[0m'

    # Unicode icons
    set -l CHECK_MARK "✓"
    set -l CROSS_MARK "✗"
    set -l INFO_ICON ℹ
    set -l TRASH_ICON "🗑️"
    set -l ARROW "→"

    if test "$argv[1]" = --help
        printf "Clear cached secrets and environment variables\n\n"
        printf "$BOLD"USAGE:"$RESET\n"
        printf "    secrets clear [OPTIONS]\n\n"
        printf "$BOLD"OPTIONS:"$RESET\n"
        printf "    -q, --quiet-footer    Skip the footer help message\n\n"
        printf "$BOLD"EXAMPLES:"$RESET\n"
        printf "$DIM    secrets clear               # Clear all cached secrets and unset environment variables$RESET\n"
        printf "$DIM    secrets clear --quiet-footer # Clear secrets without showing footer hint$RESET\n"
        return 0
    end

    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"
    set -l cleared_count 0

    printf "$CYAN$TRASH_ICON$RESET Clearing cached secrets...\n"

    # Unset environment variables first
    if test -f "$cache_file"
        printf "$DIM  - Unsetting environment variables...$RESET\n"
        grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
            set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
            if set -q $key
                set -e $key
                set cleared_count (math $cleared_count + 1)
                printf "$DIM    $ARROW$RESET Unset: $BOLD%s$RESET\n" "$key"
            end
        end

        # Remove cache file
        printf "\n$DIM  - Removing cache file...$RESET\n"
        rm -f "$cache_file"
        printf "    $GREEN$CHECK_MARK$RESET Cache file removed: $DIM%s$RESET\n" "$cache_file"
    else
        printf "$GRAY$INFO_ICON $RESET No cache file found at: $DIM%s$RESET\n" "$cache_file"
    end

    printf "\n$GREEN$BOLD$CHECK_MARK Success!$RESET Secrets cleared\n"

    # Footer hint (skip if called with --quiet-footer flag)
    if not set -q _flag_quiet_footer
        printf "\n$DIM"
        printf "Run 'secrets refresh' to reload secrets from 1Password$RESET\n"
    end
end
