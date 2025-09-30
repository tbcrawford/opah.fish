function _secrets_doctor -d "Diagnose and validate complete setup"
    # Ensure UI functions are available
    if not functions -q _secrets_ui
        source (status dirname)/_secrets_ui.fish
    end
    
    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Diagnose and validate complete setup\n\n"
        printf "%sUSAGE:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "    secrets doctor\n\n"
        printf "%sEXAMPLES:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "%s    secrets doctor    # Run comprehensive diagnostics%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        return 0
    end

    set -l all_good true

    # Check 1Password CLI
    printf "🔍 Checking 1Password CLI...\n"
    if command -q op
        printf "  "
        _secrets_success "1Password CLI (op) is installed"
        set -l op_version (op --version 2>/dev/null || echo "unknown")
        printf "    Version: %s\n" "$op_version"
    else
        printf "  "
        _secrets_error "1Password CLI (op) is not installed"
        printf "    Install from: https://developer.1password.com/docs/cli/get-started/\n"
        set all_good false
    end

    printf "\n"

    # Check 1Password authentication
    printf "🔍 Checking 1Password authentication...\n"
    if op account list >/dev/null 2>&1
        printf "  "
        _secrets_success "Signed in to 1Password"
        set -l accounts (op account list --format=json 2>/dev/null | jq -r '.[].email' 2>/dev/null || echo "Unable to parse accounts")
        printf "    Accounts: %s\n" "$accounts"
    else
        printf "  "
        _secrets_warning "Not signed in to 1Password"
        printf "    Run: op signin\n"
        printf "    (This will be done automatically when refreshing secrets)\n"
    end

    printf "\n"

    # Check configuration file
    printf "🔍 Checking configuration file...\n"
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
        printf "  "
        _secrets_success "Configuration file found: $secrets_file"

        # Quick validation
        if grep -q "secrets:" "$secrets_file"
            printf "    Format: Valid YAML with secrets section\n"
            set -l secret_count (grep -A 100 "secrets:" "$secrets_file" | grep -c "op://" || echo "0")
            printf "    1Password references: %s\n" "$secret_count"
        else
            printf "  "
            _secrets_warning "Configuration file missing 'secrets:' section"
            set all_good false
        end
    else
        printf "  "
        _secrets_error "No configuration file found"
        printf "    Create: %s\n" "$HOME/.config/fish/secrets.yaml"
        set all_good false
    end

    printf "\n"

    # Check cache directory and file
    printf "🔍 Checking cache system...\n"
    set -l cache_dir "$HOME/.cache/fish/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"

    if test -d "$cache_dir"
        printf "  "
        _secrets_success "Cache directory exists: $cache_dir"
    else
        printf "  "
        _secrets_warning "Cache directory missing (will be created automatically)"
    end

    if test -f "$cache_file"
        printf "  "
        _secrets_success "Cache file exists: $cache_file"
        printf "    Last updated: %s\n" "$(stat -f '%Sm' "$cache_file")"
        set -l cached_secrets (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "    Cached secrets: %s\n" "$cached_secrets"
    else
        printf "  "
        _secrets_warning "Cache file missing (run 'secrets refresh' to create)"
    end

    printf "\n"

    # Check Fish shell integration
    printf "🔍 Checking Fish shell integration...\n"
    if test -d functions
        printf "  "
        _secrets_success "Running from functions directory"
    else
        printf "  "
        _secrets_warning "Functions may not be in Fish path"
    end

    # Test a simple function call
    if functions -q _secrets_load
        printf "  "
        _secrets_success "Core functions are available"
    else
        printf "  "
        _secrets_error "Core functions not loaded"
        set all_good false
    end

    printf "\n"

    # Summary
    printf "📋 Summary\n"
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    if test "$all_good" = true
        _secrets_success "All systems operational!"
        
        printf "\nNext steps:\n"
        printf "  Run 'secrets refresh' to load secrets from 1Password\n"
        printf "  Run 'secrets status' to verify loaded secrets\n"
    else
        printf "%s⚠ Some issues detected. Please address the items marked with ✗ above.%s\n\n" $__SECRETS_COLOR_WARNING $__SECRETS_COLOR_RESET
        printf "Common fixes:\n"
        printf "  Install 1Password CLI: brew install 1password-cli\n"
        printf "  Create config file: touch %s\n" "$HOME/.config/fish/secrets.yaml"
        printf "  Sign in to 1Password: op signin\n"
    end
end
