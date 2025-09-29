function _secrets_config -d "Show configuration file information and validate format"
    if test "$argv[1]" = "--help"
        echo "Show configuration file information and validate format"
        echo ""
        echo "USAGE:"
        echo "    secrets config"
        echo ""
        echo "EXAMPLES:"
        echo "    secrets config    # Show config file info and validate format"
        return 0
    end
    
    echo "1Password Secrets Configuration"
    echo "==============================="
    echo ""
    
    # Define possible secret file locations (same as in _load_secrets)
    set -l secret_paths \
        "$HOME/.config/fish/secrets.yaml" \
        "$HOME/.config/fish/secrets.yml" \
        "$HOME/.config/fish/.secrets.yaml" \
        "$HOME/.config/fish/.secrets.yml" \
        "$HOME/.config/1password-secrets/secrets.yaml" \
        "$HOME/.config/1password-secrets/secrets.yml"
    
    set -l secrets_file ""
    
    echo "Checking configuration file locations:"
    for path in $secret_paths
        if test -f "$path"
            echo "  ✓ $path (FOUND)"
            if test -z "$secrets_file"
                set secrets_file "$path"
            end
        else
            echo "  ✗ $path"
        end
    end
    
    echo ""
    
    if test -z "$secrets_file"
        echo "❌ No configuration file found!"
        echo ""
        echo "Create a secrets configuration file at one of these locations:"
        echo "  $HOME/.config/fish/secrets.yaml (recommended)"
        echo ""
        echo "Example format:"
        echo "secrets:"
        echo "  API_KEY: \"op://vault/MyVault/API Keys/api_key\""
        echo "  DATABASE_URL: \"op://vault/MyVault/Database/connection_string\""
        return 1
    end
    
    echo "Active configuration file: $secrets_file"
    echo "Last modified: $(stat -f '%Sm' '$secrets_file')"
    echo ""
    
    # Validate YAML format and show secrets
    echo "Configuration validation:"
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
                        echo "  ✓ $key: $value"
                    else
                        echo "  ⚠ $key: $value (not a 1Password reference)"
                    end
                end
            end
        end
    end < "$secrets_file"
    
    echo ""
    if test "$has_secrets_section" = true
        echo "✅ Configuration valid!"
        echo "Found $secret_count secret(s) defined"
    else
        echo "❌ No 'secrets:' section found in configuration file"
        return 1
    end
end