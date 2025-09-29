function _secrets_clear -d "Clear cached secrets and environment variables"
    if test "$argv[1]" = "--help"
        echo "Clear cached secrets and environment variables"
        echo ""
        echo "USAGE:"
        echo "    secrets clear"
        echo ""
        echo "EXAMPLES:"
        echo "    secrets clear    # Clear all cached secrets and unset environment variables"
        return 0
    end
    
    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"
    set -l cleared_count 0
    
    echo "Clearing cached secrets..."
    
    # Unset environment variables first
    if test -f "$cache_file"
        echo "Unsetting environment variables..."
        grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
            set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
            if set -q $key
                set -e $key
                set cleared_count (math $cleared_count + 1)
                echo "  Unset: $key"
            end
        end
        
        # Remove cache file
        echo "Removing cache file..."
        rm -f "$cache_file"
        echo "Cache file removed: $cache_file"
    else
        echo "No cache file found at: $cache_file"
    end
    
    echo ""
    echo "Secrets cleared successfully!"
    echo "Run 'secrets refresh' to reload secrets from 1Password."
end