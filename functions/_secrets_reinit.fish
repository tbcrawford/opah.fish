function _secrets_reinit -d "Re-initialize plugin (useful after authentication changes)"
    argparse 'h/help' -- $argv

    # Local icons specific to reinit function
    set -l RESTART_ICON "🔄"
    set -l STEP_ICON "📍"

    if set -q _flag_help
        printf "Re-initialize plugin (useful after authentication changes)\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    secrets reinit\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    secrets reinit    # Clear cache and reload all secrets%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    # Clear existing cache and environment variables
    echo ""
    echo "📍 Step 1: Clearing existing cache and environment variables..."
    echo ""
    _secrets_clear --quiet-footer
    echo ""

    # Force 1Password re-authentication check
    echo "📍 Step 2: Checking 1Password authentication..."
    if not op account list >/dev/null 2>&1
        printf "%s   Signing in to 1Password...%s\n" (set_color --dim) (set_color normal)
        if not op signin
            printf "%s%s✗ Failed: %s Could not sign in to 1Password\n" (set_color red) (set_color --bold) (set_color normal) >&2
            return 1
        end
    else
        printf "\n%s✓%s Already signed in to 1Password\n" (set_color green) (set_color normal)
    end

    # Reload secrets from configuration
    echo ""
    echo "📍 Step 3: Reloading secrets from configuration..."
    echo ""
    if _secrets_load --force
        printf "\n%s" (set_color --dim)
        printf "Run 'secrets status' to verify loaded secrets%s\n" (set_color normal)
    else
        printf "\n%s%s✗ Failed:%s Could not reinitialize secrets\n" (set_color red) (set_color --bold) (set_color normal) >&2
        printf "%s" (set_color --dim) >&2
        printf "Run 'secrets doctor' to diagnose issues%s\n" (set_color normal) >&2
        return 1
    end
end
