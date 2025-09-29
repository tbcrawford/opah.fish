function _secrets_status -d "Show status of cached secrets and configuration"
    argparse 'h/help' -- $argv

    # Load shared constants
    _secrets_constants

    set -l specific_key $argv[1]
    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"

    if set -q _flag_help
        printf "Show status of cached secrets and configuration\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
        printf "    secrets status [SECRET_NAME]\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "ARGUMENTS:"
        printf "    SECRET_NAME    Show status for specific secret (optional)\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
        printf "$SECRETS_DIM    secrets status              # Show all secrets status$SECRETS_RESET\n"
        printf "$SECRETS_DIM    secrets status API_KEY      # Show status for API_KEY only$SECRETS_RESET\n"
        return 0
    end

    # Check cache file existence
    if test -f "$cache_file"
        printf "$SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET Cache file: $SECRETS_DIM%s$SECRETS_RESET\n" "$cache_file"
        printf "$SECRETS_CLOCK_ICON Last updated: $SECRETS_DIM%s$SECRETS_RESET\n" (stat -f '%Sm' "$cache_file")
        printf "\n"

        # Count cached secrets
        set -l secret_count (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "$SECRETS_INFO_ICON Cached secrets: $SECRETS_BOLD%d$SECRETS_RESET\n\n" $secret_count

        if test -n "$specific_key"
            # Show specific secret status
            if grep -q "^set -gx $specific_key " "$cache_file"
                printf "$SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET Secret '$SECRETS_BOLD%s$SECRETS_RESET': Cached\n" "$specific_key"
                if set -q $specific_key
                    printf "$SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET Environment: Loaded\n"
                else
                    printf "$SECRETS_RED$SECRETS_CROSS_MARK$SECRETS_RESET Environment: Not loaded\n"
                end
            else
                printf "$SECRETS_RED$SECRETS_CROSS_MARK$SECRETS_RESET Secret '$SECRETS_BOLD%s$SECRETS_RESET': Not found in cache\n" "$specific_key"
            end
        else
            # Show all secrets
            printf "$SECRETS_BOLD"
            printf "Cached secrets:$SECRETS_RESET\n"
            grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
                set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
                if set -q $key
                    printf "$SECRETS_DIM  $SECRETS_ARROW$SECRETS_RESET %s: $SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET Cached & Loaded\n" "$key"
                else
                    printf "$SECRETS_DIM  $SECRETS_ARROW$SECRETS_RESET %s: $SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET Cached, $SECRETS_RED$SECRETS_CROSS_MARK$SECRETS_RESET"
                    printf "Not loaded\n" "$key"
                end
            end
        end
    else
        printf "$SECRETS_RED$SECRETS_CROSS_MARK$SECRETS_RESET Cache file: Not found\n"
        printf "$SECRETS_GRAY   Run 'secrets refresh' to create cache$SECRETS_RESET\n"
    end
end
