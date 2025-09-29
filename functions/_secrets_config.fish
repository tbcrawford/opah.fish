function _secrets_config -d "Show configuration file information and validate format"
    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Show configuration file information and validate format\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    secrets config\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    secrets config    # Show config file info and validate format%s\n" (set_color --dim) (set_color normal)
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

    printf "%s" (set_color --bold)
    printf "Checking configuration file locations:%s\n" (set_color normal)
    for path in $secret_paths
        if test -f "$path"
            printf "%s  ✓%s %s %s(FOUND)%s\n" (set_color green) (set_color normal) "$path" (set_color brblack) (set_color normal)
        else
            printf "%s  ✗%s %s\n" (set_color brblack) (set_color normal) "$path"
        end
    end

    printf "\n"

    # Use utility function to find config file
    set -l secrets_file (_secrets_find_config)
    if test $status -ne 0
        printf "%s%s✗ Error:%s No configuration file found!\n\n" (set_color red) (set_color --bold) (set_color normal)
        printf "%s%s%s\n" (set_color --bold) "Create a secrets configuration file at one of these locations:" (set_color normal)
        printf "%s  →%s %s %s(recommended)%s\n" (set_color green) (set_color normal) "$HOME/.config/fish/secrets.yaml" (set_color brblack) (set_color normal)
        printf "\n%s%s%s\n" (set_color --bold) "Example format:" (set_color normal)
        printf "%s%s%s\n" (set_color --dim) "secrets:" (set_color normal)
        printf "%s  API_KEY: \"op://vault/MyVault/API Keys/api_key\"%s\n" (set_color --dim) (set_color normal)
        printf "%s  DATABASE_URL: \"op://vault/MyVault/Database/connection_string\"%s\n" (set_color --dim) (set_color normal)
        return 1
    end

    printf "📄 Active configuration file: %s%s%s\n" (set_color --bold) "$secrets_file" (set_color normal)
    printf "🕒 Last modified: %s%s%s\n\n" (set_color --dim) (stat -f '%Sm' "$secrets_file") (set_color normal)

    # Validate YAML format and show secrets
    printf "%s%s%s\n" (set_color --bold) "Configuration validation:" (set_color normal)
    
    set -g __secrets_config_count 0
    
    # Create helper function to handle each secret
    function __config_handler
        set -l key $argv[1]
        set -l value $argv[2]
        set -g __secrets_config_count (math $__secrets_config_count + 1)
        
        if string match -q "op://*" "$value"
            printf "%s  ✓%s %s: %s%s%s\n" (set_color green) (set_color normal) "$key" (set_color --dim) "$value" (set_color normal)
        else
            printf "⚠️ %s: %s%s%s %s(not a 1Password reference)%s\n" "$key" (set_color --dim) "$value" (set_color normal) (set_color brblack) (set_color normal)
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
        printf "%s%s✓ Success!%s Configuration valid\n" (set_color green) (set_color --bold) (set_color normal)
        printf "ℹ️ Found %s%d%s secret(s) defined\n" (set_color --bold) $secret_count (set_color normal)
    else
        printf "%s%s✗ Error:%s No 'secrets:' section found in configuration file\n" (set_color red) (set_color --bold) (set_color normal)
        return 1
    end
end
