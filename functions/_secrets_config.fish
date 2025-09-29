function _secrets_config -d "Show configuration file information and validate format"
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
    set -l CONFIG_ICON "⚙️"
    set -l FILE_ICON "📄"
    set -l ARROW "→"

    if test "$argv[1]" = --help
        printf "Show configuration file information and validate format\n\n"
        printf "$BOLD"USAGE:"$RESET\n"
        printf "    secrets config\n\n"
        printf "$BOLD"EXAMPLES:"$RESET\n"
        printf "$DIM    secrets config    # Show config file info and validate format$RESET\n"
        return 0
    end

    printf "$CYAN$BOLD$CONFIG_ICON 1Password Secrets Configuration$RESET\n"
    printf "$GRAY━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$RESET\n\n"

    # Define possible secret file locations (same as in _load_secrets)
    set -l secret_paths \
        "$HOME/.config/fish/secrets.yaml" \
        "$HOME/.config/fish/secrets.yml" \
        "$HOME/.config/fish/.secrets.yaml" \
        "$HOME/.config/fish/.secrets.yml" \
        "$HOME/.config/1password-secrets/secrets.yaml" \
        "$HOME/.config/1password-secrets/secrets.yml"

    set -l secrets_file ""

    printf "$BOLD"Checking configuration file locations:"$RESET\n"
    for path in $secret_paths
        if test -f "$path"
            printf "$GREEN  $CHECK_MARK$RESET %s $GRAY(FOUND)$RESET\n" "$path"
            if test -z "$secrets_file"
                set secrets_file "$path"
            end
        else
            printf "$GRAY  $CROSS_MARK$RESET %s\n" "$path"
        end
    end

    printf "\n"

    if test -z "$secrets_file"
        printf "$RED$BOLD$CROSS_MARK Error:$RESET No configuration file found!\n\n"
        printf "$BOLD"Create a secrets configuration file at one of these locations:"$RESET\n"
        printf "$GREEN  $ARROW$RESET %s $GRAY(recommended)$RESET\n" "$HOME/.config/fish/secrets.yaml"
        printf "\n$BOLD"Example format:"$RESET\n"
        printf "$DIM"secrets:"$RESET\n"
        printf "$DIM  API_KEY: \"op://vault/MyVault/API Keys/api_key\"$RESET\n"
        printf "$DIM  DATABASE_URL: \"op://vault/MyVault/Database/connection_string\"$RESET\n"
        return 1
    end

    printf "$FILE_ICON Active configuration file: $BOLD%s$RESET\n" "$secrets_file"
    printf "🕐 Last modified: $DIM%s$RESET\n\n" (stat -f '%Sm' "$secrets_file")

    # Validate YAML format and show secrets
    printf "$BOLD"Configuration validation:"$RESET\n"
    set -l in_secrets_section false
    set -l base_indent ""
    set -l secret_count 0
    set -l has_secrets_section false

    while read -l line
        # Skip empty lines and comments
        if test -z "$line"; or string match -q "#*" "$line"
            continue
        end

        # Check if we're entering the secrets section
        if string match -q "secrets:" "$line"
            set has_secrets_section true
            set in_secrets_section true
            set base_indent (string match -r "^(\s*)" "$line" | string sub -s 2)
            continue
        end

        # If we're in the secrets section
        if test "$in_secrets_section" = true
            set -l current_indent (string match -r "^(\s*)" "$line" | string sub -s 2)

            # If indentation is less than or equal to base indent and line contains ":", we've left the secrets section
            if test (string length "$current_indent") -le (string length "$base_indent"); and string match -q "*:*" "$line"
                set in_secrets_section false
                continue
            end

            # Parse key-value pairs
            if test (string length "$current_indent") -gt (string length "$base_indent"); and string match -q "*:*" "$line"
                set -l key_value (string split -m 1 ":" "$line")
                set -l key (string trim $key_value[1])
                set -l value (string trim $key_value[2])
                set value (string replace -ra '^["\']|["\']$' '' "$value")

                if test -n "$key"; and test -n "$value"
                    set secret_count (math $secret_count + 1)
                    if string match -q "op://*" "$value"
                        printf "$GREEN  $CHECK_MARK$RESET %s: $DIM%s$RESET\n" "$key" "$value"
                    else
                        printf "$YELLOW  $WARNING_ICON$RESET %s: $DIM%s$RESET $GRAY(not a 1Password reference)$RESET\n" "$key" "$value"
                    end
                end
            end
        end
    end <"$secrets_file"

    printf "\n"
    if test "$has_secrets_section" = true
        printf "$GREEN$BOLD$CHECK_MARK Success!$RESET Configuration valid\n"
        printf "$INFO_ICON Found $BOLD%d$RESET secret(s) defined\n" $secret_count
    else
        printf "$RED$BOLD$CROSS_MARK Error:$RESET No 'secrets:' section found in configuration file\n"
        return 1
    end
end
