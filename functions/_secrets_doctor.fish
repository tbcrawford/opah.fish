function _secrets_doctor -d "Diagnose and validate complete setup"
    # Color and formatting constants
    set -l GREEN '\033[0;32m'
    set -l RED '\033[0;31m'
    set -l YELLOW '\033[0;33m'
    set -l CYAN '\033[0;36m'
    set -l GRAY '\033[0;90m'
    set -l BOLD '\033[1m'
    set -l DIM '\033[2m'
    set -l RESET '\033[0m'

    # Unicode icons
    set -l CHECK_MARK "✓"
    set -l CROSS_MARK "✗"
    set -l WARNING_ICON "⚠"
    set -l INFO_ICON ℹ
    set -l DOCTOR_ICON "🔍"
    set -l SUMMARY_ICON "📋"
    set -l ARROW "→"

    if test "$argv[1]" = --help
        printf "Diagnose and validate complete setup\n\n"
        printf "$BOLD"USAGE:"$RESET\n"
        printf "    secrets doctor\n\n"
        printf "$BOLD"EXAMPLES:"$RESET\n"
        printf "$DIM    secrets doctor    # Run comprehensive diagnostics$RESET\n"
        return 0
    end

    printf "$CYAN$BOLD$DOCTOR_ICON 1Password Secrets Doctor$RESET\n"
    printf "$GRAY━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$RESET\n\n"

    set -l all_good true

    # Check 1Password CLI
    printf "$DOCTOR_ICON Checking 1Password CLI...\n"
    if command -q op
        printf "$GREEN  $CHECK_MARK$RESET 1Password CLI (op) is installed\n"
        set -l op_version (op --version 2>/dev/null || echo "unknown")
        printf "$DIM     Version: %s$RESET\n" "$op_version"
    else
        printf "$RED  $CROSS_MARK$RESET 1Password CLI (op) is not installed\n"
        printf "$GRAY     Install from: https://developer.1password.com/docs/cli/get-started/$RESET\n"
        set all_good false
    end
    printf "\n"

    # Check 1Password authentication
    printf "$DOCTOR_ICON Checking 1Password authentication...\n"
    if op account list >/dev/null 2>&1
        printf "$GREEN  $CHECK_MARK$RESET Signed in to 1Password\n"
        set -l accounts (op account list --format=json 2>/dev/null | jq -r '.[].email' 2>/dev/null || echo "Unable to parse accounts")
        printf "$DIM     Accounts: %s$RESET\n" "$accounts"
    else
        printf "$YELLOW  $WARNING_ICON$RESET Not signed in to 1Password\n"
        printf "$GRAY     Run: op signin$RESET\n"
        printf "$GRAY     (This will be done automatically when refreshing secrets)$RESET\n"
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
        printf "$GREEN  $CHECK_MARK$RESET Configuration file found: $DIM%s$RESET\n" "$secrets_file"

        # Quick validation
        if grep -q "secrets:" "$secrets_file"
            printf "$DIM     Format: Valid YAML with secrets section$RESET\n"
            set -l secret_count (grep -A 100 "secrets:" "$secrets_file" | grep -c "op://" || echo "0")
            printf "$DIM     1Password references: %s$RESET\n" "$secret_count"
        else
            printf "$YELLOW  $WARNING_ICON$RESET Configuration file missing 'secrets:' section\n"
            set all_good false
        end
    else
        printf "$RED  $CROSS_MARK$RESET No configuration file found\n"
        printf "$GRAY     Create: %s$RESET\n" "$HOME/.config/fish/secrets.yaml"
        set all_good false
    end
    printf "\n"

    # Check cache directory and file
    printf "$DOCTOR_ICON Checking cache system...\n"
    set -l cache_dir "$HOME/.cache/fish/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"

    if test -d "$cache_dir"
        printf "$GREEN  $CHECK_MARK$RESET Cache directory exists: $DIM%s$RESET\n" "$cache_dir"
    else
        printf "$YELLOW  $WARNING_ICON$RESET Cache directory missing (will be created automatically)\n"
    end

    if test -f "$cache_file"
        printf "$GREEN  $CHECK_MARK$RESET Cache file exists: $DIM%s$RESET\n" "$cache_file"
        printf "$DIM     Last updated: %s$RESET\n" (stat -f '%Sm' "$cache_file")
        set -l cached_secrets (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "$DIM     Cached secrets: %s$RESET\n" "$cached_secrets"
    else
        printf "$YELLOW  $WARNING_ICON$RESET Cache file missing (run 'secrets refresh' to create)\n"
    end
    printf "\n"

    # Check Fish shell integration
    printf "$DOCTOR_ICON Checking Fish shell integration...\n"
    if test -d functions
        printf "$GREEN  $CHECK_MARK$RESET Running from functions directory\n"
    else
        printf "$YELLOW  $WARNING_ICON$RESET Functions may not be in Fish path\n"
    end

    # Test a simple function call
    if functions -q _load_secrets
        printf "$GREEN  $CHECK_MARK$RESET Core functions are available\n"
    else
        printf "$RED  $CROSS_MARK$RESET Core functions not loaded\n"
        set all_good false
    end
    printf "\n"

    # Summary
    printf "$CYAN$BOLD$SUMMARY_ICON Summary$RESET\n"
    printf "$GRAY━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$RESET\n"
    if test "$all_good" = true
        printf "$GREEN$BOLD$CHECK_MARK All systems operational!$RESET\n\n"
        printf "$BOLD"Next steps:"$RESET\n"
        printf "$DIM  $ARROW Run 'secrets refresh' to load secrets from 1Password$RESET\n"
        printf "$DIM  $ARROW Run 'secrets status' to verify loaded secrets$RESET\n"
    else
        printf "$YELLOW$BOLD$WARNING_ICON Some issues detected.$RESET Please address the items marked with $RED$CROSS_MARK$RESET above.\n\n"
        printf "$BOLD"Common fixes:"$RESET\n"
        printf "$DIM  $ARROW Install 1Password CLI: brew install 1password-cli$RESET\n"
        printf "$DIM  $ARROW Create config file: touch %s$RESET\n" "$HOME/.config/fish/secrets.yaml"
        printf "$DIM  $ARROW Sign in to 1Password: op signin$RESET\n"
    end
end
