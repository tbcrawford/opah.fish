function _secrets_doctor -d "Diagnose and validate complete setup"
    argparse 'h/help' -- $argv

    # Load shared constants
    _secrets_constants

    # Additional icons specific to doctor
    set -l DOCTOR_ICON "🔍"
    set -l SUMMARY_ICON "📋"

    if set -q _flag_help
        printf "Diagnose and validate complete setup\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
        printf "    secrets doctor\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
        printf "$SECRETS_DIM    secrets doctor    # Run comprehensive diagnostics$SECRETS_RESET\n"
        return 0
    end

    set -l all_good true

    # Check 1Password CLI
    printf "$DOCTOR_ICON Checking 1Password CLI...\n"
    if command -q op
        printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET 1Password CLI (op) is installed\n"
        set -l op_version (op --version 2>/dev/null || echo "unknown")
        printf "$SECRETS_DIM     Version: %s$SECRETS_RESET\n" "$op_version"
    else
        printf "$SECRETS_RED  $SECRETS_CROSS_MARK$SECRETS_RESET 1Password CLI (op) is not installed\n"
        printf "$SECRETS_GRAY     Install from: https://developer.1password.com/docs/cli/get-started/$SECRETS_RESET\n"
        set all_good false
    end
    printf "\n"

    # Check 1Password authentication
    printf "$DOCTOR_ICON Checking 1Password authentication...\n"
    if op account list >/dev/null 2>&1
        printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET Signed in to 1Password\n"
        set -l accounts (op account list --format=json 2>/dev/null | jq -r '.[].email' 2>/dev/null || echo "Unable to parse accounts")
        printf "$SECRETS_DIM     Accounts: %s$SECRETS_RESET\n" "$accounts"
    else
        printf "$SECRETS_YELLOW  $SECRETS_WARNING_ICON$SECRETS_RESET Not signed in to 1Password\n"
        printf "$SECRETS_GRAY     Run: op signin$SECRETS_RESET\n"
        printf "$SECRETS_GRAY     (This will be done automatically when refreshing secrets)$SECRETS_RESET\n"
    end
    printf "\n"

    # Check configuration file
    printf "$DOCTOR_ICON Checking configuration file...\n"
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
        printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET Configuration file found: $SECRETS_DIM%s$SECRETS_RESET\n" "$secrets_file"

        # Quick validation
        if grep -q "secrets:" "$secrets_file"
            printf "$SECRETS_DIM     Format: Valid YAML with secrets section$SECRETS_RESET\n"
            set -l secret_count (grep -A 100 "secrets:" "$secrets_file" | grep -c "op://" || echo "0")
            printf "$SECRETS_DIM     1Password references: %s$SECRETS_RESET\n" "$secret_count"
        else
            printf "$SECRETS_YELLOW  $SECRETS_WARNING_ICON$SECRETS_RESET Configuration file missing 'secrets:' section\n"
            set all_good false
        end
    else
        printf "$SECRETS_RED  $SECRETS_CROSS_MARK$SECRETS_RESET No configuration file found\n"
        printf "$SECRETS_GRAY     Create: %s$SECRETS_RESET\n" "$HOME/.config/fish/secrets.yaml"
        set all_good false
    end
    printf "\n"

    # Check cache directory and file
    printf "$DOCTOR_ICON Checking cache system...\n"
    set -l cache_dir "$HOME/.cache/fish/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"

    if test -d "$cache_dir"
        printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET Cache directory exists: $SECRETS_DIM%s$SECRETS_RESET\n" "$cache_dir"
    else
        printf "$SECRETS_YELLOW  $SECRETS_WARNING_ICON$SECRETS_RESET Cache directory missing (will be created automatically)\n"
    end

    if test -f "$cache_file"
        printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET Cache file exists: $SECRETS_DIM%s$SECRETS_RESET\n" "$cache_file"
        printf "$SECRETS_DIM     Last updated: %s$SECRETS_RESET\n" (stat -f '%Sm' "$cache_file")
        set -l cached_secrets (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "$SECRETS_DIM     Cached secrets: %s$SECRETS_RESET\n" "$cached_secrets"
    else
        printf "$SECRETS_YELLOW  $SECRETS_WARNING_ICON$SECRETS_RESET Cache file missing (run 'secrets refresh' to create)\n"
    end
    printf "\n"

    # Check Fish shell integration
    printf "$DOCTOR_ICON Checking Fish shell integration...\n"
    if test -d functions
        printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET Running from functions directory\n"
    else
        printf "$SECRETS_YELLOW  $SECRETS_WARNING_ICON$SECRETS_RESET Functions may not be in Fish path\n"
    end

    # Test a simple function call
    if functions -q _secrets_load
        printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET Core functions are available\n"
    else
        printf "$SECRETS_RED  $SECRETS_CROSS_MARK$SECRETS_RESET Core functions not loaded\n"
        set all_good false
    end
    printf "\n"

    # Summary
    printf "$SECRETS_CYAN$SECRETS_BOLD$SUMMARY_ICON Summary$SECRETS_RESET\n"
    printf "$SECRETS_GRAY━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$SECRETS_RESET\n"
    if test "$all_good" = true
        printf "$SECRETS_GREEN$SECRETS_BOLD$SECRETS_CHECK_MARK All systems operational!$SECRETS_RESET\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "Next steps:"
        printf "  $SECRETS_DIM$SECRETS_ARROW Run 'secrets refresh' to load secrets from 1Password$SECRETS_RESET\n"
        printf "  $SECRETS_DIM$SECRETS_ARROW Run 'secrets status' to verify loaded secrets$SECRETS_RESET\n"
    else
        printf "$SECRETS_YELLOW$SECRETS_BOLD$SECRETS_WARNING_ICON Some issues detected.$SECRETS_RESET Please address the items marked with $SECRETS_RED$SECRETS_CROSS_MARK$SECRETS_RESET above.\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "Common fixes:"
        printf "  $SECRETS_DIM$SECRETS_ARROW Install 1Password CLI: brew install 1password-cli$SECRETS_RESET\n"
        printf "  $SECRETS_DIM$SECRETS_ARROW Create config file: touch %s$SECRETS_RESET\n" "$HOME/.config/fish/secrets.yaml"
        printf "  $SECRETS_DIM$SECRETS_ARROW Sign in to 1Password: op signin$SECRETS_RESET\n"
    end
end
