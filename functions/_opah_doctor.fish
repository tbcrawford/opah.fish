function _opah_doctor -d "Diagnose and validate complete setup"
    # Ensure UI functions are available
    if not functions -q _opah_ui
        source (status dirname)/_opah_ui.fish
    end
    
    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Diagnose and validate complete setup\n\n"
        printf "%sUSAGE:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    opah doctor\n\n"
        printf "%sEXAMPLES:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "%s    opah doctor    # Run comprehensive diagnostics%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l all_good true

    # Check 1Password CLI
    printf "🔍 Checking 1Password CLI...\n"
    if command -q op
        printf "  "
        _opah_success "1Password CLI (op) is installed"
        set -l op_version (op --version 2>/dev/null || echo "unknown")
        printf "    %sVersion: %s%s\n" $__OPAH_COLOR_DIM "$op_version" $__OPAH_COLOR_RESET
    else
        printf "  "
        _opah_error "1Password CLI (op) is not installed"
        printf "    %sInstall from: https://developer.1password.com/docs/cli/get-started/%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        set all_good false
    end

    printf "\n"

    # Check 1Password authentication
    printf "🔍 Checking 1Password authentication...\n"
    if op account list >/dev/null 2>&1
        printf "  "
        _opah_success "Signed in to 1Password"
        set -l accounts (op account list --format=json 2>/dev/null | jq -r '.[].email' 2>/dev/null || echo "Unable to parse accounts")
        printf "    %sAccounts: %s%s\n" $__OPAH_COLOR_DIM "$accounts" $__OPAH_COLOR_RESET
    else
        printf "  "
        _opah_warning "Not signed in to 1Password"
        printf "    %sRun: op signin%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "    %s(This will be done automatically when refreshing secrets)%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
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
        _opah_success "Configuration file found: $(_opah_dim $secrets_file)"

        # Quick validation
        if grep -q "secrets:" "$secrets_file"
            printf "    %sFormat: Valid YAML with secrets section%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
            set -l secret_count (grep -A 100 "secrets:" "$secrets_file" | grep -c "op://" || echo "0")
            printf "    %s1Password references: %s%s\n" $__OPAH_COLOR_DIM "$secret_count" $__OPAH_COLOR_RESET
        else
            printf "  "
            _opah_warning "Configuration file missing 'secrets:' section"
            set all_good false
        end
    else
        printf "  "
        _opah_error "No configuration file found"
        printf "    %sCreate: %s%s\n" $__OPAH_COLOR_DIM "$HOME/.config/fish/secrets.yaml" $__OPAH_COLOR_RESET
        set all_good false
    end

    printf "\n"

    # Check cache directory and file
    printf "🔍 Checking cache system...\n"
    set -l cache_dir "$HOME/.cache/fish/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"

    if test -d "$cache_dir"
        printf "  "
        _opah_success "Cache directory exists: $(_opah_dim $cache_dir)"
    else
        printf "  "
        _opah_warning "Cache directory missing (will be created automatically)"
    end

    if test -f "$cache_file"
        printf "  "
        _opah_success "Cache file exists: $(_opah_dim $cache_file)"
        printf "    %sLast updated: %s%s\n" $__OPAH_COLOR_DIM "$(stat -f '%Sm' "$cache_file")" $__OPAH_COLOR_RESET
        set -l cached_secrets (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "    %sCached secrets: %s%s\n" $__OPAH_COLOR_DIM "$cached_secrets" $__OPAH_COLOR_RESET
    else
        printf "  "
        _opah_warning "Cache file missing (run 'opah refresh' to create)"
    end

    printf "\n"

    # Check Fish shell integration
    printf "🔍 Checking Fish shell integration...\n"
    if test -d functions
        printf "  "
        _opah_success "Running from functions directory"
    else
        printf "  "
        _opah_warning "Functions may not be in Fish path"
    end

    # Test a simple function call
    if functions -q _opah_load
        printf "  "
        _opah_success "Core functions are available"
    else
        printf "  "
        _opah_error "Core functions not loaded"
        set all_good false
    end

    printf "\n"

    # Summary
    printf "📋 Summary\n"
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    if test "$all_good" = true
        _opah_success "All systems operational!"
        
        printf "\n%sNext steps:%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "    %sRun 'opah refresh' to load secrets from 1Password%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "    %sRun 'opah status' to verify loaded secrets%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    else
        printf "%s⚠ Some issues detected. Please address the items marked with ✗ above.%s\n\n" $__OPAH_COLOR_WARNING $__OPAH_COLOR_RESET
        printf "%sCommon fixes:%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "    %sInstall 1Password CLI: brew install 1password-cli%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "    %sCreate config file: touch %s%s\n" $__OPAH_COLOR_DIM "$HOME/.config/fish/secrets.yaml" $__OPAH_COLOR_RESET
        printf "    %sSign in to 1Password: op signin%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    end
end
