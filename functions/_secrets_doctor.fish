function _secrets_doctor -d "Diagnose and validate complete setup"
    argparse 'h/help' -- $argv

    # Additional icons specific to doctor
    set -l DOCTOR_ICON "🔍"
    set -l SUMMARY_ICON "📋"

    if set -q _flag_help
        printf "Diagnose and validate complete setup\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    secrets doctor\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    secrets doctor    # Run comprehensive diagnostics%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    set -l all_good true

    # Check 1Password CLI
    printf "$DOCTOR_ICON Checking 1Password CLI...\n"
    if command -q op
        printf "%s  ✓%s 1Password CLI (op) is installed\n" (set_color green) (set_color normal)
        set -l op_version (op --version 2>/dev/null || echo "unknown")
        printf "%s     Version: %s%s\n" (set_color --dim) "$op_version" (set_color normal)
    else
        printf "%s  ✗%s 1Password CLI (op) is not installed\n" (set_color red) (set_color normal)
        printf "%s     Install from: https://developer.1password.com/docs/cli/get-started/%s\n" (set_color brblack) (set_color normal)
        set all_good false
    end
    printf "\n"

    # Check 1Password authentication
    printf "$DOCTOR_ICON Checking 1Password authentication...\n"
    if op account list >/dev/null 2>&1
        printf "%s  ✓%s Signed in to 1Password\n" (set_color green) (set_color normal)
        set -l accounts (op account list --format=json 2>/dev/null | jq -r '.[].email' 2>/dev/null || echo "Unable to parse accounts")
        printf "%s     Accounts: %s%s\n" (set_color --dim) "$accounts" (set_color normal)
    else
        printf "⚠️ Not signed in to 1Password\n"
        printf "%s     Run: op signin%s\n" (set_color brblack) (set_color normal)
        printf "%s     (This will be done automatically when refreshing secrets)%s\n" (set_color brblack) (set_color normal)
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
        printf "%s  ✓%s Configuration file found: %s%s%s\n" (set_color green) (set_color normal) (set_color --dim) "$secrets_file" (set_color normal)

        # Quick validation
        if grep -q "secrets:" "$secrets_file"
            printf "%s     Format: Valid YAML with secrets section%s\n" (set_color --dim) (set_color normal)
            set -l secret_count (grep -A 100 "secrets:" "$secrets_file" | grep -c "op://" || echo "0")
            printf "%s     1Password references: %s%s\n" (set_color --dim) "$secret_count" (set_color normal)
        else
        printf "⚠️ Configuration file missing 'secrets:' section\n"
            set all_good false
        end
    else
        printf "%s  ✗%s No configuration file found\n" (set_color red) (set_color normal)
        printf "%s     Create: %s%s\n" (set_color brblack) "$HOME/.config/fish/secrets.yaml" (set_color normal)
        set all_good false
    end
    printf "\n"

    # Check cache directory and file
    printf "$DOCTOR_ICON Checking cache system...\n"
    set -l cache_dir "$HOME/.cache/fish/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"

    if test -d "$cache_dir"
        printf "%s  ✓%s Cache directory exists: %s%s%s\n" (set_color green) (set_color normal) (set_color --dim) "$cache_dir" (set_color normal)
    else
        printf "⚠️ Cache directory missing (will be created automatically)\n"
    end

    if test -f "$cache_file"
        printf "%s  ✓%s Cache file exists: %s%s%s\n" (set_color green) (set_color normal) (set_color --dim) "$cache_file" (set_color normal)
        printf "%s     Last updated: %s%s\n" (set_color --dim) (stat -f '%Sm' "$cache_file") (set_color normal)
        set -l cached_secrets (grep -c "^set -gx" "$cache_file" 2>/dev/null || echo "0")
        printf "%s     Cached secrets: %s%s\n" (set_color --dim) "$cached_secrets" (set_color normal)
    else
        printf "⚠️ Cache file missing (run 'secrets refresh' to create)\n"
    end
    printf "\n"

    # Check Fish shell integration
    printf "$DOCTOR_ICON Checking Fish shell integration...\n"
    if test -d functions
        printf "%s  ✓%s Running from functions directory\n" (set_color green) (set_color normal)
    else
        printf "⚠️ Functions may not be in Fish path\n"
    end

    # Test a simple function call
    if functions -q _secrets_load
        printf "%s  ✓%s Core functions are available\n" (set_color green) (set_color normal)
    else
        printf "%s  ✗%s Core functions not loaded\n" (set_color red) (set_color normal)
        set all_good false
    end
    printf "\n"

    # Summary
    printf "%s%s$SUMMARY_ICON Summary%s\n" (set_color cyan) (set_color --bold) (set_color normal)
    printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" (set_color brblack) (set_color normal)
    if test "$all_good" = true
        printf "%s%s✓ All systems operational!%s\n\n" (set_color green) (set_color --bold) (set_color normal)
        printf "%s%s%s\n" (set_color --bold) "Next steps:" (set_color normal)
        printf "  %s→ Run 'secrets refresh' to load secrets from 1Password%s\n" (set_color --dim) (set_color normal)
        printf "  %s→ Run 'secrets status' to verify loaded secrets%s\n" (set_color --dim) (set_color normal)
    else
        printf "%s⚠️ Some issues detected.%s Please address the items marked with %s✗%s above.\n\n" (set_color --bold) (set_color normal) (set_color red) (set_color normal)
        printf "%s%s%s\n" (set_color --bold) "Common fixes:" (set_color normal)
        printf "  %s→ Install 1Password CLI: brew install 1password-cli%s\n" (set_color --dim) (set_color normal)
        printf "  %s→ Create config file: touch %s%s\n" (set_color --dim) "$HOME/.config/fish/secrets.yaml" (set_color normal)
        printf "  %s→ Sign in to 1Password: op signin%s\n" (set_color --dim) (set_color normal)
    end
end
