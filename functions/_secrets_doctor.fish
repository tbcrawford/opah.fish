function _secrets_doctor -d "Diagnose and validate complete setup"
    if test "$argv[1]" = "--help"
        echo "Diagnose and validate complete setup"
        echo ""
        echo "USAGE:"
        echo "    secrets doctor"
        echo ""
        echo "EXAMPLES:"
        echo "    secrets doctor    # Run comprehensive diagnostics"
        return 0
    end
    
    echo "1Password Secrets Doctor"
    echo "========================"
    echo ""
    
    set -l all_good true
    
    # Check 1Password CLI
    echo "🔍 Checking 1Password CLI..."
    if command -q op
        echo "  ✅ 1Password CLI (op) is installed"
        set -l op_version (op --version 2>/dev/null || echo "unknown")
        echo "     Version: $op_version"
    else
        echo "  ❌ 1Password CLI (op) is not installed"
        echo "     Install from: https://developer.1password.com/docs/cli/get-started/"
        set all_good false
    end
    echo ""
    
    # Check 1Password authentication
    echo "🔍 Checking 1Password authentication..."
    if op account list >/dev/null 2>&1
        echo "  ✅ Signed in to 1Password"
        set -l accounts (op account list --format=json 2>/dev/null | jq -r '.[].email' 2>/dev/null || echo "Unable to parse accounts")
        echo "     Accounts: $accounts"
    else
        echo "  ⚠️  Not signed in to 1Password"
        echo "     Run: op signin"
        echo "     (This will be done automatically when refreshing secrets)"
    end
    echo ""
    
    # Check configuration file
    echo "🔍 Checking configuration file..."
    set -l secret_paths \
        "$HOME/.config/fish/secrets.yaml" \
        "$HOME/.config/fish/secrets.yml" \
        "$HOME/.config/fish/.secrets.yaml" \
        "$HOME/.config/fish/.secrets.yml" \
        "$HOME/.config/1password-secrets/secrets.yaml" \
        "$HOME/.config/1password-secrets/secrets.yml"
    
    set -l secrets_file ""
    for path in $secret_paths
        if test -f "$path"
            set secrets_file "$path"
            break
        end
    end
    
    if test -n "$secrets_file"
        echo "  ✅ Configuration file found: $secrets_file"
        
        # Quick validation
        if grep -q "secrets:" "$secrets_file"
            echo "     Format: Valid YAML with secrets section"
            set -l secret_count (grep -A 100 "secrets:" "$secrets_file" | grep -c "op://" || echo "0")
            echo "     1Password references: $secret_count"
        else
            echo "  ⚠️  Configuration file missing 'secrets:' section"
            set all_good false
        end
    else
        echo "  ❌ No configuration file found"
        echo "     Create: $HOME/.config/fish/secrets.yaml"
        set all_good false
    end
    echo ""
    
    # Check cache directory and file
    echo "🔍 Checking cache system..."
    set -l cache_dir "$HOME/.cache/fish/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"
    
    if test -d "$cache_dir"
        echo "  ✅ Cache directory exists: $cache_dir"
    else
        echo "  ⚠️  Cache directory missing (will be created automatically)"
    end
    
    if test -f "$cache_file"
        echo "  ✅ Cache file exists: $cache_file"
        echo "     Last updated: $(stat -f '%Sm' '$cache_file')"
        set -l cached_secrets (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        echo "     Cached secrets: $cached_secrets"
    else
        echo "  ⚠️  Cache file missing (run 'secrets refresh' to create)"
    end
    echo ""
    
    # Check Fish shell integration
    echo "🔍 Checking Fish shell integration..."
    if test -d functions
        echo "  ✅ Running from functions directory"
    else
        echo "  ⚠️  Functions may not be in Fish path"
    end
    
    # Test a simple function call
    if functions -q _load_secrets
        echo "  ✅ Core functions are available"
    else
        echo "  ❌ Core functions not loaded"
        set all_good false
    end
    echo ""
    
    # Summary
    echo "📋 Summary"
    echo "=========="
    if test "$all_good" = true
        echo "✅ All systems operational!"
        echo ""
        echo "Next steps:"
        echo "  • Run 'secrets refresh' to load secrets from 1Password"
        echo "  • Run 'secrets status' to verify loaded secrets"
    else
        echo "⚠️  Some issues detected. Please address the items marked with ❌ above."
        echo ""
        echo "Common fixes:"
        echo "  • Install 1Password CLI: brew install 1password-cli"
        echo "  • Create config file: touch $HOME/.config/fish/secrets.yaml"
        echo "  • Sign in to 1Password: op signin"
    end
end