function _load_secrets --description "Load secrets from 1Password CLI with permanent caching"
    # Initialize cache directory
    set -l cache_dir "$__fish_cache_dir/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"
    
    # Define possible secret file locations in order of preference
    set -l secret_paths \
        "$HOME/.config/fish/secrets.yaml" \
        "$HOME/.config/fish/secrets.yml" \
        "$HOME/.config/fish/.secrets.yaml" \
        "$HOME/.config/fish/.secrets.yml" \
        "$HOME/.config/1password-secrets/secrets.yaml" \
        "$HOME/.config/1password-secrets/secrets.yml"
    
    # Find the first existing secrets file
    set -l secrets_file ""
    for path in $secret_paths
        if test -f "$path"
            set secrets_file "$path"
            break
        end
    end
    
    # Check if secrets mapping file exists
    if test -z "$secrets_file"
        echo "Error: No secrets file found in any of the expected locations" >&2
        return 1
    end

    # Check for force refresh flag
    set -l force_refresh false
    if contains -- --force $argv
        set force_refresh true
    end

    # Use cached secrets if they exist and force refresh is not requested
    if test -f "$cache_file" -a "$force_refresh" = false
        source "$cache_file"
        return 0
    end

    # Check if 1Password CLI is available
    if not command -q op
        echo "Error: 1Password CLI (op) is not installed or not in PATH" >&2
        echo "Please install it from: https://developer.1password.com/docs/cli/get-started/" >&2
        return 1
    end

    # Check if user is signed in to 1Password
    if not op account list --format=json >/dev/null 2>&1
        echo "Error: Not signed in to 1Password CLI" >&2
        echo "Please run: op signin" >&2
        return 1
    end

    echo "Loading secrets from 1Password..."

    # Create cache directory if it doesn't exist
    mkdir -p "$cache_dir"

    # Create temporary file for building cache
    set -l temp_cache (mktemp)

    # Add header to cache file
    echo "# Cached secrets from 1Password CLI" >"$temp_cache"
    echo "# Generated on: $(date)" >>"$temp_cache"
    echo "" >>"$temp_cache"

    # Counter for success/failure tracking
    set -l success_count 0
    set -l total_count 0

    # Parse YAML and extract key-value pairs under 'secrets' key
    set -l in_secrets_section false
    set -l base_indent ""
    
    while read -l line
        # Skip empty lines and comments
        if test -z "$line"; or string match -q "#*" "$line"
            continue
        end
        
        # Check if we're entering the secrets section
        if string match -q "secrets:" "$line"
            set in_secrets_section true
            # Get the base indentation level
            set base_indent (string match -r "^(\s*)" "$line" | string sub -s 2)
            continue
        end
        
        # If we're in the secrets section
        if test "$in_secrets_section" = true
            # Get current line's indentation
            set -l current_indent (string match -r "^(\s*)" "$line" | string sub -s 2)
            
            # If indentation is less than or equal to base indent and line contains ":", 
            # we've left the secrets section
            if test (string length "$current_indent") -le (string length "$base_indent"); and string match -q "*:*" "$line"
                set in_secrets_section false
                continue
            end
            
            # Parse key-value pairs (only if indented more than base)
            if test (string length "$current_indent") -gt (string length "$base_indent"); and string match -q "*:*" "$line"
                set total_count (math $total_count + 1)
                
                # Extract key and value
                set -l key_value (string split -m 1 ":" "$line")
                set -l key (string trim $key_value[1])
                set -l value (string trim $key_value[2])
                
                # Remove quotes from value if present
                set value (string replace -ra '^["\']|["\']$' '' "$value")
                
                # Fetch value from 1Password and set environment variable
                if test -n "$key"; and test -n "$value"
                    echo "  Fetching $key..."
                    
                    # Fetch the actual secret value from 1Password
                    set -l secret_value (op read "$value" 2>/dev/null)
                    
                    if test $status -eq 0; and test -n "$secret_value"
                        # Escape single quotes and backslashes in the secret value
                        set secret_value (string replace -a "'" "'\\''" "$secret_value")
                        set secret_value (string replace -a "\\" "\\\\" "$secret_value")
                        
                        # Write to cache file and set the variable
                        echo "set -gx $key '$secret_value'" >>"$temp_cache"
                        set -gx $key "$secret_value"
                        
                        set success_count (math $success_count + 1)
                    else
                        echo "Warning: Failed to fetch $key from 1Password path: $value" >&2
                    end
                end
            end
        end
    end < "$secrets_file"

    # Move temp file to final cache location
    mv "$temp_cache" "$cache_file"

    echo "Successfully loaded $success_count/$total_count secrets from 1Password"

    if test $success_count -eq 0
        echo "Error: No secrets were successfully loaded" >&2
        return 1
    end

    return 0
end