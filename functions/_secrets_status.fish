function _secrets_status -d "Show status of cached secrets and configuration"
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
    set -l CLOCK_ICON "🕐"
    set -l FILE_ICON "📄"
    set -l ARROW "→"

    set -l specific_key $argv[1]
    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"

    if test "$argv[1]" = --help
        printf "Show status of cached secrets and configuration\n\n"
        printf "$BOLD"USAGE:"$RESET\n"
        printf "    secrets status [SECRET_NAME]\n\n"
        printf "$BOLD"ARGUMENTS:"$RESET\n"
        printf "    SECRET_NAME    Show status for specific secret (optional)\n\n"
        printf "$BOLD"EXAMPLES:"$RESET\n"
        printf "$DIM    secrets status              # Show all secrets status$RESET\n"
        printf "$DIM    secrets status API_KEY      # Show status for API_KEY only$RESET\n"
        return 0
    end

    printf "$CYAN$BOLD$FILE_ICON 1Password Secrets Status$RESET\n"
    printf "$GRAY━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$RESET\n\n"

    # Check cache file existence
    if test -f "$cache_file"
        printf "$GREEN$CHECK_MARK$RESET Cache file: $DIM%s$RESET\n" "$cache_file"
        printf "$CLOCK_ICON Last updated: $DIM%s$RESET\n" (stat -f '%Sm' "$cache_file")
        printf "\n"

        # Count cached secrets
        set -l secret_count (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "$INFO_ICON Cached secrets: $BOLD%d$RESET\n\n" $secret_count

        if test -n "$specific_key"
            # Show specific secret status
            if grep -q "^set -gx $specific_key " "$cache_file"
                printf "$GREEN$CHECK_MARK$RESET Secret '$BOLD%s$RESET': Cached\n" "$specific_key"
                if set -q $specific_key
                    printf "$GREEN$CHECK_MARK$RESET Environment: Loaded\n"
                else
                    printf "$RED$CROSS_MARK$RESET Environment: Not loaded\n"
                end
            else
                printf "$RED$CROSS_MARK$RESET Secret '$BOLD%s$RESET': Not found in cache\n" "$specific_key"
            end
        else
            # Show all secrets
            printf "$BOLD"Cached secrets:"$RESET\n"
            grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
                set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
                if set -q $key
                    printf "$DIM  $ARROW$RESET %s: $GREEN$CHECK_MARK$RESET Cached & Loaded\n" "$key"
                else
                    printf "$DIM  $ARROW$RESET %s: $GREEN$CHECK_MARK$RESET Cached, $RED$CROSS_MARK$RESET Not loaded\n" "$key"
                end
            end
        end
    else
        printf "$RED$CROSS_MARK$RESET Cache file: Not found\n"
        printf "$GRAY   Run 'secrets refresh' to create cache$RESET\n"
    end
end
