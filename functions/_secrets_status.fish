function _secrets_status -d "Show status of cached secrets and configuration"
    argparse 'h/help' -- $argv

    set -l specific_key $argv[1]
    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"

    if set -q _flag_help
        printf "Show status of cached secrets and configuration\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    secrets status [SECRET_NAME]\n\n"
        printf "%s%s%s\n" (set_color --bold) "ARGUMENTS:" (set_color normal)
        printf "    SECRET_NAME    Show status for specific secret (optional)\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    secrets status              # Show all secrets status%s\n" (set_color --dim) (set_color normal)
        printf "%s    secrets status API_KEY      # Show status for API_KEY only%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    # Check cache file existence
    if test -f "$cache_file"
        printf "%s✓%s Cache file: %s%s%s\n" (set_color green) (set_color normal) (set_color --dim) "$cache_file" (set_color normal)
        printf "🕒 Last updated: %s%s%s\n" (set_color --dim) (stat -f '%Sm' "$cache_file") (set_color normal)
        printf "\n"

        # Count cached secrets
        set -l secret_count (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "ℹ️  Cached secrets: %s%d%s\n\n" (set_color --bold) $secret_count (set_color normal)

        if test -n "$specific_key"
            # Show specific secret status
            if grep -q "^set -gx $specific_key " "$cache_file"
                printf "%s✓%s Secret '%s%s%s': Cached\n" (set_color green) (set_color normal) (set_color --bold) "$specific_key" (set_color normal)
                if set -q $specific_key
                    printf "%s✓%s Environment: Loaded\n" (set_color green) (set_color normal)
                else
                    printf "%s✗%s Environment: Not loaded\n" (set_color red) (set_color normal)
                end
            else
                printf "%s✗%s Secret '%s%s%s': Not found in cache\n" (set_color red) (set_color normal) (set_color --bold) "$specific_key" (set_color normal)
            end
        else
            # Show all secrets
            printf "%sCached secrets:%s\n" (set_color --bold) (set_color normal)
            grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
                set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
                if set -q $key
                    printf "%s  →%s %s: %s✓%s Cached & Loaded\n" (set_color --dim) (set_color normal) "$key" (set_color green) (set_color normal)
                else
                    printf "%s  →%s %s: %s✓%s Cached, %s✗%s Not loaded\n" (set_color --dim) (set_color normal) "$key" (set_color green) (set_color normal) (set_color red) (set_color normal)
                end
            end
        end
    else
        printf "%s✗%s Cache file: Not found\n" (set_color red) (set_color normal)
        printf "%s   Run 'secrets refresh' to create cache%s\n" (set_color brblack) (set_color normal)
    end
end