function _secrets_refresh -d "Refresh secrets from 1Password"
    set -l specific_key $argv[1]
    
    if test "$argv[1]" = "--help"
        echo "Refresh secrets from 1Password (with auto-login prompting)"
        echo ""
        echo "USAGE:"
        echo "    secrets refresh [SECRET_NAME]"
        echo ""
        echo "ARGUMENTS:"
        echo "    SECRET_NAME    Refresh specific secret only (optional)"
        echo ""
        echo "EXAMPLES:"
        echo "    secrets refresh              # Refresh all secrets"
        echo "    secrets refresh DATABASE_URL # Refresh DATABASE_URL only"
        return 0
    end
    
    if test -n "$specific_key"
        echo "Refreshing specific secret: $specific_key"
        # For specific key refresh, we need to re-parse the config and only update that key
        # This is more complex, so for now just refresh all
        echo "Note: Specific key refresh not yet implemented, refreshing all secrets"
    else
        echo "Refreshing all secrets from 1Password..."
    end
    
    # Call the main load function which handles 1Password authentication and caching
    _load_secrets
end