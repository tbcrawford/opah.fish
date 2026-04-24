#
# Show status of cached secrets and configuration
#
# Displays the current status of cached secrets including cache file location,
# last update time, and a list of all cached secrets. Can show status for all
# secrets or a specific secret. Indicates whether each secret is cached and
# loaded into the environment.
#
# @param SECRET_NAME Optional secret name to show status for only that secret
# @param -h/--help Shows usage information and examples
# @return 0 always succeeds
#
function _opah_status -d "Show status of cached secrets and configuration"
    functions -q _opah_success; or source (status dirname)/_opah_ui.fish
    functions -q _opah_get_cache_file; or source (status dirname)/_opah_paths.fish
    functions -q _opah_mtime; or source (status dirname)/_opah_platform.fish
    functions -q _opah_cache_count; or source (status dirname)/_opah_cache.fish

    argparse h/help -- $argv

    set -l specific_key $argv[1]

    set -l cache_file (_opah_get_cache_file)

    if set -q _flag_help
        printf "Show status of cached secrets and configuration\n\n"
        printf "%sUSAGE:%s\n" (set_color --bold) (set_color normal)
        printf "    opah status [SECRET_NAME]\n\n"
        printf "%sARGUMENTS:%s\n" (set_color --bold) (set_color normal)
        printf "    SECRET_NAME    Show status for specific secret (optional)\n\n"
        printf "%sEXAMPLES:%s\n" (set_color --bold) (set_color normal)
        printf "%s    opah status              # Show all opah status%s\n" (set_color --dim) (set_color normal)
        printf "%s    opah status API_KEY      # Show status for API_KEY only%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    # Check cache file existence
    if test -f "$cache_file"
        _opah_file "Cache file: "(_opah_dim $cache_file)
        _opah_info "Last updated: "(_opah_dim (_opah_mtime "$cache_file"))

        # Check cache file permissions
        set -l cache_perms (_opah_perms "$cache_file")
        if test "$cache_perms" = 600
            _opah_info "Permissions: "(_opah_dim "Secure (600)")
        else
            _opah_warning "Permissions: $cache_perms (should be 600)"
        end

        # Count cached secrets
        set -l secret_count (_opah_cache_count "$cache_file")
        printf "\n"
        _opah_info "Cached secrets: $secret_count"

        if test -n "$specific_key"
            printf "\n"
            # Show specific secret status
            set -l keys (_opah_cache_keys "$cache_file")
            if contains "$specific_key" $keys
                _opah_success "Secret '"(_opah_bold $specific_key)"': Cached"
                if set -q $specific_key
                    _opah_success "Environment: Loaded"
                else
                    _opah_error "Environment: Not loaded"
                end
            else
                _opah_error "Secret '"(_opah_bold $specific_key)"': Not found in cache"
            end
        else
            printf "\n"
            # Show all secrets
            printf "%sCached secrets:%s\n" (set_color --bold) (set_color normal)
            _opah_cache_keys "$cache_file" | while read -l key
                if set -q $key
                    printf "    %s%s:%s %s✓%s Cached & Loaded\n" (set_color --dim) "$key" (set_color normal) (set_color green) (set_color normal)
                else
                    printf "    %s%s:%s %s✓%s Cached, %s✗%s Not loaded\n" (set_color --dim) "$key" (set_color normal) (set_color green) (set_color normal) (set_color red) (set_color normal)
                end
            end
        end
    else
        _opah_error "Cache file: Not found"
        _opah_hint "opah refresh" "to create cache"
    end
end
