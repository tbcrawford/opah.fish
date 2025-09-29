function _secrets_load --description "Load secrets from 1Password CLI with permanent caching"
    argparse 'h/help' 'f/force' 'k/key=' -- $argv
    # Load shared constants
    _secrets_constants

    if set -q _flag_help
        printf "Load secrets from 1Password CLI with permanent caching\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "USAGE:"
        printf "    _secrets_load [OPTIONS]\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "OPTIONS:"
        printf "    -h, --help            Show this help message\n"
        printf "    -f, --force           Force refresh of all secrets\n"
        printf "    -k, --key=KEY         Refresh specific secret only\n\n"
        printf "$SECRETS_BOLD%s$SECRETS_RESET\n" "EXAMPLES:"
        printf "$SECRETS_DIM    _secrets_load                    # Load from cache or fetch if missing$SECRETS_RESET\n"
        printf "$SECRETS_DIM    _secrets_load --force            # Force refresh all secrets$SECRETS_RESET\n"
        printf "$SECRETS_DIM    _secrets_load --key=API_KEY      # Refresh only API_KEY$SECRETS_RESET\n"
        return 0
    end

    # Initialize cache directory
    set -l cache_dir "$__fish_cache_dir/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"

    # Find the secrets configuration file
    set -l secrets_file (_secrets_find_config)
    if test $status -ne 0
        printf "$SECRETS_RED$SECRETS_CROSS_MARK $SECRETS_RESET No secrets configuration found\n" >&2
        printf "$SECRETS_GRAY   Expected locations:$SECRETS_RESET\n" >&2
        set -l secret_paths \
            "$HOME/.config/fish/secrets.yaml" \
            "$HOME/.config/fish/secrets.yml" \
            "$HOME/.config/fish/.secrets.yaml" \
            "$HOME/.config/fish/.secrets.yml" \
            "$HOME/.config/1password-secrets/secrets.yaml" \
            "$HOME/.config/1password-secrets/secrets.yml"
        for path in $secret_paths
            printf "$SECRETS_GRAY   $SECRETS_ARROW %s$SECRETS_RESET\n" "$path" >&2
        end
        return 1
    end

    # Check for force refresh flag
    set -l force_refresh false
    if set -q _flag_force
        set force_refresh true
    end

    # Check for specific key to refresh
    set -g specific_key ""
    if set -q _flag_key
        set specific_key "$_flag_key"
        set force_refresh true  # Force refresh when targeting specific key
    end

    # Use cached secrets if they exist and force refresh is not requested
    if test -f "$cache_file" -a "$force_refresh" = false
        source "$cache_file"
        return 0
    end

    # If refreshing specific key, load existing cache first then update only that key
    if test -n "$specific_key" -a -f "$cache_file"
        source "$cache_file"
    end

    # Check if 1Password CLI is available
    if not command -q op
        printf "$SECRETS_RED$SECRETS_CROSS_MARK $SECRETS_RESET 1Password CLI not found\n" >&2
        printf "$SECRETS_GRAY   Install from: https://developer.1password.com/docs/cli/get-started/$SECRETS_RESET\n" >&2
        return 1
    end

    # Check if user is signed in to 1Password
    if not op account list --format=json >/dev/null 2>&1
        printf "$SECRETS_RED$SECRETS_CROSS_MARK $SECRETS_RESET Not signed in to 1Password\n" >&2
        printf "$SECRETS_GRAY%s$SECRETS_BOLD%s$SECRETS_RESET$SECRETS_GRAY%s$SECRETS_RESET\n" "   Run: " "op signin" " to authenticate" >&2
        return 1
    end

    printf "$SECRETS_CYAN$SECRETS_LOCK_ICON$SECRETS_RESET Loading secrets from 1Password...\n"

    # Create cache directory if it doesn't exist
    mkdir -p "$cache_dir"

    # Create temporary file for building cache
    set -g temp_cache (mktemp)

    # If updating specific key, start with existing cache content
    if test -n "$specific_key" -a -f "$cache_file"
        cp "$cache_file" "$temp_cache"
    else
        # Add header to cache file
        echo "# Cached secrets from 1Password CLI" >"$temp_cache"
        echo "# Generated on: $(date)" >>"$temp_cache"
        echo "" >>"$temp_cache"
    end

    # Counter for success/failure tracking (using global scope for function access)
    set -g success_count 0
    set -g total_count 0
    set -g key_found false

    # Create handler function to process each secret
    function __load_handler
        set -l key $argv[1]
        set -l value $argv[2]
        set total_count (math $total_count + 1)

        # Check if this is the specific key we're looking for
        if test -n "$specific_key"
            if test "$key" = "$specific_key"
                set key_found true
            else
                return 0
            end
        end

        printf "$SECRETS_DIM   $SECRETS_ARROW %s$SECRETS_RESET" "$key"

        # Fetch the actual secret value from 1Password
        set -l secret_value (op read "$value" 2>/dev/null)

        if test $status -eq 0; and test -n "$secret_value"
            # Escape single quotes and backslashes in the secret value
            set secret_value (string replace -a "'" "'\\''" "$secret_value")
            set secret_value (string replace -a "\\" "\\\\" "$secret_value")

            # For specific key refresh, update the cache file by replacing the line
            if test -n "$specific_key"
                # Remove existing line for this key and add new one
                sed -i '' "/^set -gx $key /d" "$temp_cache" 2>/dev/null
                echo "set -gx $key '$secret_value'" >>"$temp_cache"
            else
                # Write to cache file normally
                echo "set -gx $key '$secret_value'" >>"$temp_cache"
            end
            
            set -gx $key "$secret_value"

            printf " $SECRETS_GREEN$SECRETS_CHECK_MARK$SECRETS_RESET\n"
            set success_count (math $success_count + 1)
        else
            printf " $SECRETS_RED$SECRETS_CROSS_MARK $SECRETS_RESET\n"
            printf "$SECRETS_YELLOW   Warning: Failed to fetch from $value$SECRETS_RESET\n" >&2
        end
    end

    # Parse YAML and extract key-value pairs under 'secrets' key
    _secrets_parse_yaml "$secrets_file" __load_handler

    # Move temp file to final cache location
    mv "$temp_cache" "$cache_file"
    
    # Clean up global temp_cache variable
    set -e temp_cache

    # Clean up global counter variables after use
    set -l final_success_count $success_count
    set -l final_total_count $total_count
    set -l final_key_found $key_found
    set -l final_specific_key $specific_key
    set -e success_count
    set -e total_count
    set -e key_found
    set -e specific_key

    # Check if specific key was found
    if test -n "$final_specific_key" -a "$final_key_found" = false
        printf "$SECRETS_RED$SECRETS_BOLD$SECRETS_CROSS_MARK Failed: $SECRETS_RESET Secret '$final_specific_key' not found in configuration\n" >&2
        return 1
    end

    # Display results with modern formatting
    if test -n "$final_specific_key"
        if test $final_success_count -eq 1
            printf "$SECRETS_GREEN$SECRETS_BOLD$SECRETS_CHECK_MARK Success!$SECRETS_RESET $SECRETS_GREEN%s refreshed$SECRETS_RESET\n" "$final_specific_key"
        else
            printf "$SECRETS_RED$SECRETS_BOLD$SECRETS_CROSS_MARK Failed: $SECRETS_RESET Unable to refresh %s\n" "$final_specific_key" >&2
            return 1
        end
    else if test $final_success_count -eq $final_total_count; and test $final_success_count -gt 0
        printf "\n$SECRETS_GREEN$SECRETS_BOLD$SECRETS_CHECK_MARK Success! $SECRETS_RESET$SECRETS_GREEN%d secrets loaded$SECRETS_RESET\n" $final_success_count
    else if test $final_success_count -gt 0
        printf "$SECRETS_YELLOW$SECRETS_BOLD$SECRETS_INFO_ICON Partial success: $SECRETS_RESET $SECRETS_GREEN%d$SECRETS_RESET/$SECRETS_YELLOW%d$SECRETS_RESET secrets loaded\n" $final_success_count $final_total_count
    else
        printf "$SECRETS_RED$SECRETS_BOLD$SECRETS_CROSS_MARK Failed: $SECRETS_RESET No secrets loaded\n" >&2
        return 1
    end

    return 0
end
