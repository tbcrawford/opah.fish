#
# Show configuration file information and validate format
#
# Displays information about the opah configuration file location and
# validates its format. Shows all possible configuration file locations
# and indicates which ones exist. Parses and validates the YAML structure
# of the configuration file if found.
#
# @param -h/--help Shows usage information and examples
# @return 0 on success, 1 if no configuration file is found or validation fails
#
function _opah_config -d "Show configuration file information and validate format"
    # Initialize UI functions
    if not functions -q _opah_init_ui
        source (status dirname)/_opah_init_ui.fish
    end
    _opah_init_ui
    
    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Show configuration file information and validate format\n\n"
        printf "%sUSAGE:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    opah config\n\n"
        printf "%sEXAMPLES:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "%s    opah config    # Show config file info and validate format%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    # Ensure path utilities are available
    if not functions -q _opah_get_config_paths
        source (status dirname)/_opah_paths.fish
    end

    # Get possible secret file locations from centralized function
    set -l secret_paths (_opah_get_config_paths)

    printf "Checking configuration file locations:\n"
    for path in $secret_paths
        if test -f "$path"
            _opah_success "$(_opah_dim $path) (FOUND)"
        else
            _opah_error "$(_opah_dim $path)"
        end
    end

    printf "\n"

    # Use utility function to find config file
    set -l secrets_file (_opah_find_config)
    if test $status -ne 0
        _opah_error "Error: No configuration file found!"
        printf "\nCreate a opah configuration file at one of these locations:\n"
        printf "%s  %s (recommended)%s\n" $__OPAH_COLOR_DIM "$HOME/.config/fish/secrets.yaml" $__OPAH_COLOR_RESET
        printf "\n%sExample format:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "%s    secrets:%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "%s      API_KEY: \"op://vault/MyVault/API Keys/api_key\"%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "%s      DATABASE_URL: \"op://vault/MyVault/Database/connection_string\"%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 1
    end

    _opah_file "Active configuration file: $(_opah_dim $secrets_file)"
    _opah_info "Last modified: $(_opah_dim "$(stat -f '%Sm' "$secrets_file")")"

    # Validate YAML format and show secrets
    printf "\nConfiguration validation:\n"
    
    set -l config_count 0
    
    # Create helper function to handle each secret (avoiding global variables)
    function __config_handler --description "Handle configuration validation for each secret"
        set -l key $argv[1]
        set -l value $argv[2]
        # Use parent scope variable
        set config_count (math $config_count + 1)
        
        if string match -q "op://*" "$value"
            printf "    %s✓%s %s%s:%s %s%s%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM "$key" $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM "$value" $__OPAH_COLOR_RESET
        else
            printf "    %s⚠%s %s%s:%s %s%s%s %s(not a 1Password reference)%s\n" $__OPAH_COLOR_WARNING $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM "$key" $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM "$value" $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        end
    end
    
    # Parse the YAML file  
    _opah_parse_yaml "$secrets_file" __config_handler
    # Immediately capture the result before any other operations
    set -l parse_result $status

    printf "\n"
    if test $parse_result -eq 0
        _opah_success "Success! Configuration valid"
        _opah_info "Found $(_opah_dim $config_count) secret(s) defined"
    else
        _opah_error "Error: No 'secrets:' section found in configuration file"
        return 1
    end
end
