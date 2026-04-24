#
# Load secrets from 1Password CLI with data-based caching
#
# Loads secrets from 1Password and caches them in a secure data format.
# Can load from cache, force refresh all secrets, or refresh a specific secret.
# Validates 1Password CLI availability and authentication before fetching secrets.
# Creates environment variables for each secret defined in the configuration file.
#
# This refactored version uses:
# - Stream-based parsing (no callbacks or global state)
# - Data cache format (tab-separated, escaped values)
# - Pure Fish operations (no external sed/grep dependencies)
# - Proper error handling and validation
#
# @param -h/--help Shows usage information and examples
# @param -f/--force Forces refresh of all secrets from 1Password
# @param -k/--key=KEY Refreshes only the specified secret key
# @return 0 on success, 1 if configuration not found or 1Password CLI unavailable
#
function _opah_load --description "Load secrets from 1Password CLI with data-based caching"
    argparse 'h/help' 'f/force' 'k/key=' -- $argv

    if set -q _flag_help
        printf "Load secrets from 1Password CLI with data-based caching\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    _opah_load [OPTIONS]\n\n"
        printf "%s%s%s\n" (set_color --bold) "OPTIONS:" (set_color normal)
        printf "    -h, --help            Show this help message\n"
        printf "    -f, --force           Force refresh of all secrets\n"
        printf "    -k, --key=KEY         Refresh specific secret only\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    _opah_load                    # Load from cache or fetch if missing%s\n" (set_color --dim) (set_color normal)
        printf "%s    _opah_load --force            # Force refresh all secrets%s\n" (set_color --dim) (set_color normal)
        printf "%s    _opah_load --key=API_KEY      # Refresh only API_KEY%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    # Initialize cache paths
    set -l cache_dir (_opah_get_cache_dir)
    set -l cache_file (_opah_get_cache_file)

    # Find the opah configuration file
    set -l config_file (_opah_find_config)
    if test $status -ne 0
        _opah_error "No opah configuration found" >&2
        printf "%s   Expected locations:%s\n" (set_color --dim) (set_color normal) >&2
        _opah_get_config_paths | while read -l path
            printf "%s   %s%s\n" (set_color --dim) "$path" (set_color normal) >&2
        end
        return 1
    end

    # Determine operation mode
    set -l force_refresh false
    set -l specific_key ""
    
    if set -q _flag_force
        set force_refresh true
    end
    
    if set -q _flag_key
        set specific_key "$_flag_key"
        set force_refresh true  # Force refresh when targeting specific key
    end

    # Use cached secrets if available and not forcing refresh
    if test -f "$cache_file" -a "$force_refresh" = false
        _opah_cache_read "$cache_file" >/dev/null
        return 0
    end

    # Check if 1Password CLI is available
    if not command -q op
        _opah_error "1Password CLI not found" >&2
        _opah_hint "Install from: https://developer.1password.com/docs/cli/get-started/" >&2
        return 1
    end

    # Check if user is signed in to 1Password
    if not op account list --format=json >/dev/null 2>&1
        _opah_error "Not signed in to 1Password" >&2
        _opah_hint "op signin" "to authenticate" >&2
        return 1
    end

    _opah_security "Loading secrets from 1Password..."

    # Create cache directory if needed
    mkdir -p "$cache_dir"

    # Parse configuration and fetch secrets
    set -l success_count 0
    set -l total_count 0
    set -l key_found false
    
    # Create temporary storage for cache entries (secure permissions immediately)
    set -l temp_entries (mktemp)
    chmod 600 "$temp_entries"
    
    # If updating specific key, load existing cache first
    if test -n "$specific_key" -a -f "$cache_file"
        # Copy existing cache entries (skip comments)
        while read -l line
            if not string match -qr '^\s*(#|$)' "$line"
                echo "$line" >>"$temp_entries"
            end
        end <"$cache_file"
        
        # Also load existing secrets into environment
        _opah_cache_read "$cache_file" >/dev/null
    end
    
    # Process each secret from config
    _opah_parse_yaml "$config_file" | while read -l key op_ref
        set total_count (math $total_count + 1)
        
        # If targeting specific key, skip others
        if test -n "$specific_key"
            if test "$key" != "$specific_key"
                continue
            else
                set key_found true
            end
        end
        
        printf "  %s" "$key"
        
        # Fetch secret from 1Password
        set -l secret_value (op read "$op_ref" 2>&1)
        set -l op_status $status
        
        if test $op_status -eq 0
            # Store in temp entries file
            if test -n "$specific_key"
                # Update mode: remove old entry for this key
                set -l new_temp (mktemp)
                while read -l line
                    if not string match -qr "^$key\t" "$line"
                        echo "$line" >>"$new_temp"
                    end
                end <"$temp_entries"
                mv "$new_temp" "$temp_entries"
            end
            
            # Add new entry
            printf '%s\t%s\n' "$key" "$secret_value" >>"$temp_entries"
            
            # Export to environment
            set -gx $key "$secret_value"
            
            printf " %s✓%s\n" (set_color green) (set_color normal)
            set success_count (math $success_count + 1)
        else
            printf " %s✗%s\n" (set_color red) (set_color normal)
            printf "%sWarning: Failed to fetch secret for key: %s%s\n" (set_color yellow) "$key" (set_color normal) >&2
        end
    end
    
    # Write cache using helper function
    _opah_cache_write "$cache_file" <"$temp_entries"
    
    # Cleanup
    rm -f "$temp_entries"
    
    # Check if specific key was found
    if test -n "$specific_key" -a "$key_found" = false
        _opah_error "Failed: Secret '$specific_key' not found in configuration" >&2
        return 1
    end
    
    # Display results
    if test -n "$specific_key"
        if test $success_count -eq 1
            printf "\n"
            _opah_success "Success! $specific_key refreshed"
        else
            _opah_error "Failed: Unable to refresh $specific_key" >&2
            return 1
        end
    else if test $success_count -eq $total_count; and test $success_count -gt 0
        printf "\n"
        _opah_success "Success! $success_count secrets loaded"
    else if test $success_count -gt 0
        printf "\n"
        _opah_info "Partial success: $success_count/$total_count secrets loaded"
    else
        _opah_error "Failed: No secrets loaded" >&2
        return 1
    end
    
    return 0
end
