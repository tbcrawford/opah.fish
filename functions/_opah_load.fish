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
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section Usage
        printf "  %s_opah_load%s %s[OPTIONS]%s\n" \
            $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        _opah_section Options
        printf "  %s-f, --force%s  %sforce refresh of all secrets%s\n" \
            $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "  %s-k, --key%s    %srefresh specific secret only%s\n" \
            $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    argparse f/force 'k/key=' -- $argv

    # Initialize cache paths
    set -l cache_dir (_opah_get_cache_dir)
    set -l cache_file (_opah_get_cache_file)

    # Find the opah configuration file
    set -l config_file (_opah_find_config)
    if test $status -ne 0
        _opah_error "No configuration found" >&2
        _opah_hint "create: ~/.config/fish/secrets.yaml" >&2
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
        set force_refresh true # Force refresh when targeting specific key
    end

    # Use cached secrets if available and not forcing refresh
    if test -f "$cache_file" -a "$force_refresh" = false
        # Detect stale v0.1.0 cache (executable Fish: `set -gx KEY value`)
        # New format is tab-separated data; old format causes silent zero-secrets load
        set -l is_legacy false
        while read -l line
            string match -qr '^\s*(#|$)' -- "$line"; and continue
            if string match -qr '^set -gx ' -- "$line"
                set is_legacy true
            end
            break
        end <"$cache_file"

        if test "$is_legacy" = false
            _opah_cache_read "$cache_file" >/dev/null
            return 0
        end

        # Old format detected; fall through to refresh from 1Password
        _opah_warning "Cache format outdated — refreshing from 1Password" >&2
    end

    # Check if 1Password CLI is available
    if not command -q op
        _opah_error "op is not installed" >&2
        _opah_hint "install from: https://developer.1password.com/docs/cli/get-started/" >&2
        return 1
    end

    # Check if user is signed in to 1Password
    if not op account list --format=json >/dev/null 2>&1
        _opah_error "Not signed in to 1Password" >&2
        _opah_hint "run: op signin to authenticate" >&2
        return 1
    end

    _opah_info "Loading secrets from 1Password..."
    echo

    # Create cache directory if needed
    mkdir -p "$cache_dir"

    # Handle single-key refresh separately to avoid double-escaping existing cache entries
    if test -n "$specific_key"
        # Load existing cache into environment first (so other vars stay set)
        if test -f "$cache_file"
            _opah_cache_read "$cache_file" >/dev/null
        end

        # Find the op:// reference for this key in the config
        set -l op_ref ""
        _opah_parse_yaml "$config_file" | while read -l key value
            if test "$key" = "$specific_key"
                set op_ref "$value"
            end
        end

        if test -z "$op_ref"
            _opah_error "Secret '$specific_key' not found in configuration" >&2
            return 1
        end

        set -l col_width (math (string length "$specific_key") + 5)
        set -l key_dots "$specific_key..."
        printf "  %s%-*s%s" $__OPAH_COLOR_DIM $col_width "$key_dots" $__OPAH_COLOR_RESET

        set -l secret_value (op read "$op_ref" 2>/dev/null)
        if test $status -eq 0; and test -n "$secret_value"
            # Use _opah_cache_update which copies existing entries as-is (no double-escaping)
            if test -f "$cache_file"
                _opah_cache_update "$cache_file" "$specific_key" "$secret_value"
            else
                printf '%s\t%s\n' "$specific_key" "$secret_value" | _opah_cache_write "$cache_file"
            end
            set -gx $specific_key "$secret_value"
            printf "%s✓%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
        else
            printf "%s✕%s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
            _opah_error "Failed to refresh $specific_key" >&2
            return 1
        end
        return 0
    end

    # Full fetch: parse all secrets and build a fresh cache
    set -l success_count 0
    set -l total_count 0

    # Collect keys and refs in one pass, compute col_width at the same time
    set -l all_keys
    set -l all_refs
    set -l col_width 10
    _opah_parse_yaml "$config_file" | while read -l key op_ref
        set -a all_keys $key
        set -a all_refs $op_ref
        set -l w (math (string length "$key") + 5)
        if test $w -gt $col_width
            set col_width $w
        end
    end

    # Create temporary storage for cache entries (secure permissions immediately)
    set -l temp_entries (mktemp)
    chmod 600 "$temp_entries"

    # Process each secret from config
    for i in (seq 1 (count $all_keys))
        set -l key $all_keys[$i]
        set -l op_ref $all_refs[$i]
        set total_count (math $total_count + 1)

        set -l key_dots "$key..."
        printf "  %s%-*s%s" $__OPAH_COLOR_DIM $col_width "$key_dots" $__OPAH_COLOR_RESET

        # Fetch secret from 1Password
        set -l secret_value (op read "$op_ref" 2>/dev/null)

        if test $status -eq 0; and test -n "$secret_value"
            # Store raw value; _opah_cache_write will escape it
            printf '%s\t%s\n' "$key" "$secret_value" >>"$temp_entries"

            # Export to environment immediately
            set -gx $key "$secret_value"

            printf "%s✓%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
            set success_count (math $success_count + 1)
        else
            printf "%s✕%s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET >&2
        end
    end
    echo

    # Display results and write cache only if at least one secret was loaded
    if test $success_count -eq $total_count; and test $success_count -gt 0
        _opah_cache_write "$cache_file" <"$temp_entries"
        rm -f "$temp_entries"
        _opah_success "$success_count secrets loaded"
    else if test $success_count -gt 0
        _opah_cache_write "$cache_file" <"$temp_entries"
        rm -f "$temp_entries"
        _opah_warning "$success_count of $total_count secrets loaded"
    else
        rm -f "$temp_entries"
        _opah_error "No secrets loaded" >&2
        return 1
    end

    return 0
end
