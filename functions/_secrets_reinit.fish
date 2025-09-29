function _secrets_reinit -d "Re-initialize plugin (useful after authentication changes)"
    if test "$argv[1]" = "--help"
        echo "Re-initialize plugin (useful after authentication changes)"
        echo ""
        echo "USAGE:"
        echo "    secrets reinit"
        echo ""
        echo "EXAMPLES:"
        echo "    secrets reinit    # Clear cache and reload all secrets"
        return 0
    end
    
    echo "Re-initializing 1Password Secrets Plugin"
    echo "========================================"
    echo ""
    
    # Clear existing cache and environment variables
    echo "Step 1: Clearing existing cache and environment variables..."
    _secrets_clear
    echo ""
    
    # Force 1Password re-authentication check
    echo "Step 2: Checking 1Password authentication..."
    if not op account list >/dev/null 2>&1
        echo "Signing in to 1Password..."
        if not op signin
            echo "❌ Failed to sign in to 1Password"
            return 1
        end
    else
        echo "✅ Already signed in to 1Password"
    end
    echo ""
    
    # Reload secrets from configuration
    echo "Step 3: Reloading secrets from configuration..."
    if _load_secrets
        echo "✅ Successfully reinitialized!"
        echo ""
        echo "Run 'secrets status' to verify loaded secrets."
    else
        echo "❌ Failed to reinitialize secrets"
        echo "Run 'secrets doctor' to diagnose issues."
        return 1
    end
end