function _secrets_config -d "Show configuration file information and validate format"
    # Ensure UI functions are available
    if not functions -q _secrets_ui
        source (status dirname)/_secrets_ui.fish
    end
    
    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Show configuration file information and validate format\n\n"
        printf "%sUSAGE:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "    secrets config\n\n"
        printf "%sEXAMPLES:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "%s    secrets config    # Show config file info and validate format%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
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

    printf "Checking configuration file locations:\n"
    for path in $secret_paths
        if test -f "$path"
            _secrets_success "$(_secrets_dim $path) (FOUND)"
        else
            _secrets_error "$(_secrets_dim $path)"
        end
    end

    printf "\n"

    # Use utility function to find config file
    set -l secrets_file (_secrets_find_config)
    if test $status -ne 0
        _secrets_error "Error: No configuration file found!"
        printf "\nCreate a secrets configuration file at one of these locations:\n"
        printf "%s  %s (recommended)%s\n" $__SECRETS_COLOR_DIM "$HOME/.config/fish/secrets.yaml" $__SECRETS_COLOR_RESET
        printf "\n%sExample format:%s\n" $__SECRETS_COLOR_BOLD $__SECRETS_COLOR_RESET
        printf "%s    secrets:%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        printf "%s      API_KEY: \"op://vault/MyVault/API Keys/api_key\"%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        printf "%s      DATABASE_URL: \"op://vault/MyVault/Database/connection_string\"%s\n" $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
        return 1
    end

    _secrets_file "Active configuration file: $(_secrets_dim $secrets_file)"
    _secrets_info "Last modified: $(_secrets_dim "$(stat -f '%Sm' "$secrets_file")")"

    # Validate YAML format and show secrets
    printf "\nConfiguration validation:\n"
    
    set -g __secrets_config_count 0
    
    # Create helper function to handle each secret
    function __config_handler
        set -l key $argv[1]
        set -l value $argv[2]
        set -g __secrets_config_count (math $__secrets_config_count + 1)
        
        if string match -q "op://*" "$value"
            printf "    %s✓%s %s%s:%s %s%s%s\n" $__SECRETS_COLOR_SUCCESS $__SECRETS_COLOR_RESET $__SECRETS_COLOR_DIM "$key" $__SECRETS_COLOR_RESET $__SECRETS_COLOR_DIM "$value" $__SECRETS_COLOR_RESET
        else
            printf "    %s⚠%s %s%s:%s %s%s%s %s(not a 1Password reference)%s\n" $__SECRETS_COLOR_WARNING $__SECRETS_COLOR_RESET $__SECRETS_COLOR_DIM "$key" $__SECRETS_COLOR_RESET $__SECRETS_COLOR_DIM "$value" $__SECRETS_COLOR_RESET $__SECRETS_COLOR_DIM $__SECRETS_COLOR_RESET
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
        _secrets_success "Success! Configuration valid"
        _secrets_info "Found $(_secrets_dim $secret_count) secret(s) defined"
    else
        _secrets_error "Error: No 'secrets:' section found in configuration file"
        return 1
    end
end
