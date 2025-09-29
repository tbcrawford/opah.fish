function _secrets_status -d "Show status of cached secrets and configuration"
    set -l specific_key $argv[1]
    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"
    
    if test "$argv[1]" = "--help"
        echo "Show status of cached secrets and configuration"
        echo ""
        echo "USAGE:"
        echo "    secrets status [SECRET_NAME]"
        echo ""
        echo "ARGUMENTS:"
        echo "    SECRET_NAME    Show status for specific secret (optional)"
        echo ""
        echo "EXAMPLES:"
        echo "    secrets status              # Show all secrets status"
        echo "    secrets status API_KEY      # Show status for API_KEY only"
        return 0
    end
    
    echo "1Password Secrets Status"
    echo "========================"
    echo ""
    
    # Check cache file existence
    if test -f "$cache_file"
        echo "Cache file: $cache_file ✓"
        echo "Last updated: $(stat -f '%Sm' '$cache_file')"
        echo ""
        
        # Count cached secrets
        set -l secret_count (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        echo "Cached secrets: $secret_count"
        echo ""
        
        if test -n "$specific_key"
            # Show specific secret status
            if grep -q "^set -gx $specific_key " "$cache_file"
                echo "Secret '$specific_key': ✓ Cached"
                if set -q $specific_key
                    echo "Environment: ✓ Loaded"
                else
                    echo "Environment: ✗ Not loaded"
                end
            else
                echo "Secret '$specific_key': ✗ Not found in cache"
            end
        else
            # Show all secrets
            echo "Cached secrets:"
            grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
                set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
                if set -q $key
                    echo "  $key: ✓ Cached & Loaded"
                else
                    echo "  $key: ✓ Cached, ✗ Not loaded"
                end
            end
        end
    else
        echo "Cache file: ✗ Not found"
        echo "Run 'secrets refresh' to create cache"
    end
end