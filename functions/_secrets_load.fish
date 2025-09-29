function _secrets_load --description "Load secrets from 1Password CLI with permanent caching"
    argparse 'f/force' 'k/key=' -- $argv
    # Color and formatting constants
    set -l RED '\033[0;31m'
    set -l GREEN '\033[0;32m'
    set -l YELLOW '\033[0;33m'
    set -l BLUE '\033[0;34m'
    set -l PURPLE '\033[0;35m'
    set -l CYAN '\033[0;36m'
    set -l GRAY '\033[0;90m'
    set -l BOLD '\033[1m'
    set -l DIM '\033[2m'
    set -l RESET '\033[0m'

    # Unicode icons
    set -l CHECK_MARK "✓"
    set -l CROSS_MARK "✗"
    set -l INFO_ICON ℹ
    set -l LOCK_ICON "🔐"
    set -l ARROW "→"

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
        printf "$RED$CROSS_MARK $RESET No secrets configuration found\n" >&2
        printf "$GRAY   Expected locations:$RESET\n" >&2
        for path in $secret_paths
            printf "$GRAY   $ARROW %s$RESET\n" "$path" >&2
        end
        return 1
    end

    # Check for force refresh flag
    set -l force_refresh false
    if set -q _flag_force
        set force_refresh true
    end

    # Check for specific key to refresh
    set -l specific_key ""
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
        printf "$RED$CROSS_MARK $RESET 1Password CLI not found\n" >&2
        printf "$GRAY   Install from: https://developer.1password.com/docs/cli/get-started/$RESET\n" >&2
        return 1
    end

    # Check if user is signed in to 1Password
    if not op account list --format=json >/dev/null 2>&1
        printf "$RED$CROSS_MARK $RESET Not signed in to 1Password\n" >&2
        printf "$GRAY   Run: "$BOLD"op signin"$RESET$GRAY" to authenticate"$RESET"\n" >&2
        return 1
    end

    printf "$CYAN$LOCK_ICON$RESET Loading secrets from 1Password...\n"

    # Create cache directory if it doesn't exist
    mkdir -p "$cache_dir"

    # Create temporary file for building cache
    set -l temp_cache (mktemp)

    # If updating specific key, start with existing cache content
    if test -n "$specific_key" -a -f "$cache_file"
        cp "$cache_file" "$temp_cache"
    else
        # Add header to cache file
        echo "# Cached secrets from 1Password CLI" >"$temp_cache"
        echo "# Generated on: $(date)" >>"$temp_cache"
        echo "" >>"$temp_cache"
    end

    # Counter for success/failure tracking
    set -l success_count 0
    set -l total_count 0
    set -l key_found false

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
                    # Check if this is the specific key we're looking for
                    if test -n "$specific_key"
                        if test "$key" = "$specific_key"
                            set key_found true
                        else
                            continue
                        end
                    end

                    printf "$DIM   $ARROW %s$RESET" "$key"

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

                        printf " $GREEN$CHECK_MARK$RESET\n"
                        set success_count (math $success_count + 1)
                    else
                        printf " $RED$CROSS_MARK $RESET\n"
                        printf "$YELLOW   Warning: Failed to fetch from $value$RESET\n" >&2
                    end
                end
            end
        end
    end <"$secrets_file"

    # Move temp file to final cache location
    mv "$temp_cache" "$cache_file"

    # Check if specific key was found
    if test -n "$specific_key" -a "$key_found" = false
        printf "$RED$BOLD$CROSS_MARK Failed: $RESET Secret '$specific_key' not found in configuration\n" >&2
        return 1
    end

    # Display results with modern formatting
    if test -n "$specific_key"
        if test $success_count -eq 1
            printf "$GREEN$BOLD$CHECK_MARK Success!$RESET $GREEN%s refreshed$RESET\n" "$specific_key"
        else
            printf "$RED$BOLD$CROSS_MARK Failed: $RESET Unable to refresh %s\n" "$specific_key" >&2
            return 1
        end
    else if test $success_count -eq $total_count; and test $success_count -gt 0
        printf "\n$GREEN$BOLD$CHECK_MARK Success! $RESET$GREEN%d secrets loaded$RESET\n" $success_count
    else if test $success_count -gt 0
        printf "$YELLOW$BOLD$INFO_ICON Partial success: $RESET $GREEN%d$RESET/$YELLOW%d$RESET secrets loaded\n" $success_count $total_count
    else
        printf "$RED$BOLD$CROSS_MARK Failed: $RESET No secrets loaded\n" >&2
        return 1
    end

    return 0
end
