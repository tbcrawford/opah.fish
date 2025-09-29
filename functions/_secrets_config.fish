function _secrets_config -d "Show configuration file information and validate format"
    # Load shared constants
    _secrets_constants

    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Show configuration file information and validate format\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
        printf "    secrets config\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
        printf "$SECRETS_DIM    secrets config    # Show config file info and validate format$SECRETS_RESET\n"
        return 0
    end

    # Define possible secret file locations (same as in _secrets_load)
    set -l secret_paths \
        "$HOME/.config/fish/secrets.yaml" \
        "$HOME/.config/fish/secrets.yml" \
        "$HOME/.config/fish/.secrets.yaml" \
        "$HOME/.config/fish/.secrets.yml" \
        "$HOME/.config/1password-secrets/secrets.yaml" \
        "$HOME/.config/1password-secrets/secrets.yml"

    printf "$SECRETS_BOLD"
    printf "Checking configuration file locations:$SECRETS_RESET\n"
    for path in $secret_paths
        if test -f "$path"
            printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET %s $SECRETS_GRAY(FOUND)$SECRETS_RESET\n" "$path"
        else
            printf "$SECRETS_GRAY  $SECRETS_CROSS_MARK$SECRETS_RESET %s\n" "$path"
        end
    end

    printf "\n"

    # Use utility function to find config file
    set -l secrets_file (_secrets_find_config)
    if test $status -ne 0
        printf "$SECRETS_RED$SECRETS_BOLD$SECRETS_CROSS_MARK Error:$SECRETS_RESET No configuration file found!\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "Create a secrets configuration file at one of these locations:"
        printf "$SECRETS_GREEN  $SECRETS_ARROW$SECRETS_RESET %s $SECRETS_GRAY(recommended)$SECRETS_RESET\n" "$HOME/.config/fish/secrets.yaml"
        printf "\n$SECRETS_BOLD%s$SECRETS_RESET\n" "Example format:"
        printf "$SECRETS_DIM%s$SECRETS_RESET\n" "secrets:"
        printf "$SECRETS_DIM  API_KEY: \"op://vault/MyVault/API Keys/api_key\"$SECRETS_RESET\n"
        printf "$SECRETS_DIM  DATABASE_URL: \"op://vault/MyVault/Database/connection_string\"$SECRETS_RESET\n"
        return 1
    end

    printf "$SECRETS_FILE_ICON Active configuration file: $SECRETS_BOLD%s$SECRETS_RESET\n" "$secrets_file"
    printf "🕐 Last modified: $SECRETS_DIM%s$SECRETS_RESET\n\n" (stat -f '%Sm' "$secrets_file")

    # Validate YAML format and show secrets
    printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "Configuration validation:"
    
    set -g __secrets_config_count 0
    
    # Create helper function to handle each secret
    function __config_handler
        set -l key $argv[1]
        set -l value $argv[2]
        set -g __secrets_config_count (math $__secrets_config_count + 1)
        
        if string match -q "op://*" "$value"
            printf "$SECRETS_GREEN  $SECRETS_CHECK_MARK$SECRETS_RESET %s: $SECRETS_DIM%s$SECRETS_RESET\n" "$key" "$value"
        else
            printf "$SECRETS_YELLOW  $SECRETS_WARNING_ICON$SECRETS_RESET %s: $SECRETS_DIM%s$SECRETS_RESET $SECRETS_GRAY(not a 1Password reference)$SECRETS_RESET\n" "$key" "$value"
        end
    end
    
    # Parse the YAML file  
    _secrets_parse_yaml "$secrets_file" __config_handler
    # Immediately capture the result before any other operations
    set -l parse_result $status
    
    # Now get the count and clean up
    set -l secret_count $__secrets_config_count
    set -e __secrets_config_count

    printf "\n"
    if test $parse_result -eq 0
        printf "$SECRETS_GREEN$SECRETS_BOLD$SECRETS_CHECK_MARK Success!$SECRETS_RESET Configuration valid\n"
        printf "$SECRETS_INFO_ICON Found $SECRETS_BOLD%d$SECRETS_RESET secret(s) defined\n" $secret_count
    else
        printf "$SECRETS_RED$SECRETS_BOLD$SECRETS_CROSS_MARK Error:$SECRETS_RESET No 'secrets:' section found in configuration file\n"
        return 1
    end
end
