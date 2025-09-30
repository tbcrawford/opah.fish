#
# Parse secrets from YAML configuration file and call handler function for each secret
#
# Parses a YAML configuration file looking for a "secrets:" section and extracts
# key-value pairs from it. For each secret found, calls the provided handler
# function with the key and value as arguments. This allows flexible processing
# of secrets without hardcoding the action to take for each secret.
#
# @param config_file The path to the YAML configuration file
# @param handler_function The name of the function to call for each secret (will be called with key and value)
# @return 0 if secrets section found and processed, 1 if config file not found or invalid arguments
#
function _opah_parse_yaml -d "Parse secrets from YAML configuration file and call handler function for each secret"
    set -l config_file $argv[1]
    set -l handler_function $argv[2]
    
    if test -z "$config_file" -o -z "$handler_function"
        echo "Usage: _opah_parse_yaml CONFIG_FILE HANDLER_FUNCTION" >&2
        return 1
    end
    
    if not test -f "$config_file"
        echo "Config file not found: $config_file" >&2
        return 1
    end
    
    set -l in_opah_section false
    set -l base_indent ""
    set -l found_secrets false
    set -l secrets_processed 0
    
    while read -l line
        # Skip empty lines and comments
        if test -z "$line"; or string match -q "#*" "$line"
            continue
        end
        
        # Check if we're entering the secrets section
        # Match "secrets:" with optional whitespace and comments
        if string match -qr '^\s*secrets:\s*($|#.*$)' "$line"
            set in_opah_section true
            set found_secrets true
            # Get the base indentation level
            set base_indent (string match -r "^(\s*)" "$line" | string sub -s 2)
            continue
        end
        
        # If we're in the secrets section
        if test "$in_opah_section" = true
            # Get current line's indentation
            set -l current_indent (string match -r "^(\s*)" "$line" | string sub -s 2)
            
            # If indentation is less than or equal to base indent and line contains ":", 
            # we've left the secrets section
            if test (string length "$current_indent") -le (string length "$base_indent"); and string match -q "*:*" "$line"
                set in_opah_section false
                continue
            end
            
            # Parse key-value pairs (only if indented more than base)
            if test (string length "$current_indent") -gt (string length "$base_indent"); and string match -q "*:*" "$line"
                # Extract key and value
                set -l key_value (string split -m 1 ":" "$line")
                set -l key (string trim $key_value[1])
                set -l value (string trim $key_value[2])
                
                # Remove quotes from value if present
                set value (string replace -ra '^["\']|["\']$' '' "$value")
                
                # Call handler function with key and value
                if test -n "$key"; and test -n "$value"
                    $handler_function "$key" "$value"
                    set secrets_processed (math $secrets_processed + 1)
                end
            end
        end
    end <"$config_file"
    
    # Return appropriate exit code
    if test "$found_secrets" = true
        return 0
    else
        return 1
    end
end