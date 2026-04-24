#
# Parse secrets from YAML configuration file and output as tab-separated stream
#
# Parses a YAML configuration file looking for a "secrets:" section and extracts
# key-value pairs from it. Outputs each secret as a tab-separated line: KEY<tab>VALUE
# This stream-based approach is more idiomatic for Fish shell and eliminates the need
# for callback functions and global state.
#
# @param config_file The path to the YAML configuration file
# @return 0 if secrets section found and processed, 1 if config file not found or invalid arguments
#
function _opah_parse_yaml -d "Parse secrets from YAML configuration file and output as tab-separated stream"
    set -l config_file $argv[1]
    
    if test -z "$config_file"
        echo "Usage: _opah_parse_yaml CONFIG_FILE" >&2
        return 1
    end
    
    if not test -f "$config_file"
        echo "Config file not found: $config_file" >&2
        return 1
    end
    
    set -l in_secrets_section false
    set -l base_indent ""
    set -l found_secrets false
    
    while read -l line
        # Skip empty lines and comments
        if string match -qr '^\s*(#|$)' "$line"
            continue
        end
        
        # Check if we're entering the secrets section
        if string match -qr '^\s*secrets:\s*($|#.*$)' "$line"
            set in_secrets_section true
            set found_secrets true
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
                # Extract key and value
                set -l key_value (string split -m 1 ":" "$line")
                set -l key (string trim $key_value[1])
                set -l value (string trim $key_value[2])
                
                # Remove quotes from value if present
                set value (string replace -ra '^["\']|["\']$' '' "$value")
                
                # Validate key is a valid environment variable name
                if string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' "$key"
                    # Output as tab-separated stream
                    if test -n "$key"; and test -n "$value"
                        printf '%s\t%s\n' "$key" "$value"
                    end
                else if test -n "$key"
                    # Warn about invalid keys but continue processing
                    echo "Warning: Skipping invalid key '$key' (must match ^[A-Za-z_][A-Za-z0-9_]*\$)" >&2
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