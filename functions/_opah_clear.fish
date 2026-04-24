#
# Clear cached secrets and environment variables
#
# Unsets all environment variables that were loaded from 1Password secrets
# and removes the cache file. This function provides options to control
# the output verbosity.
#
# @param -h/--help Shows usage information and examples
# @param -q/--quiet-footer Skips the footer help message
# @return 0 on success
#
function _opah_clear -d "Clear cached secrets and environment variables"
    functions -q _opah_success; or source (status dirname)/_opah_ui.fish
    functions -q _opah_get_cache_file; or source (status dirname)/_opah_paths.fish
    functions -q _opah_cache_keys; or source (status dirname)/_opah_cache.fish

    argparse h/help q/quiet-footer -- $argv

    if set -q _flag_help
        printf "Clear cached secrets and environment variables\n\n"
        printf "%sUSAGE:%s\n" (set_color --bold) (set_color normal)
        printf "    opah clear [OPTIONS]\n\n"
        printf "%sOPTIONS:%s\n" (set_color --bold) (set_color normal)
        printf "    -h, --help            Show this help message\n"
        printf "    -q, --quiet-footer    Skip the footer help message\n\n"
        printf "%sEXAMPLES:%s\n" (set_color --bold) (set_color normal)
        printf "%s    opah clear                # Clear all cached secrets%s\n" (set_color --dim) (set_color normal)
        printf "%s    opah clear --quiet-footer # Clear without showing footer%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    set -l cache_file (_opah_get_cache_file)
    set -l cleared_count 0

    _opah_process "Clearing cached secrets..."

    # Unset environment variables first
    if test -f "$cache_file"
        printf "\n  %sUnsetting environment variables...%s\n" (set_color --dim) (set_color normal)
        _opah_cache_keys "$cache_file" | while read -l key
            if set -q $key
                set -e $key
                set cleared_count (math $cleared_count + 1)
                printf "    %s%s%s %s✓%s\n" (set_color --dim) "$key" (set_color normal) (set_color green) (set_color normal)
            end
        end

        # Remove cache file
        printf "\n  %sRemoving cache file...%s\n" (set_color --dim) (set_color normal)
        rm -f "$cache_file"
        printf "    %s✓%s Cache file removed: %s%s%s\n" (set_color green) (set_color normal) (set_color --dim) "$cache_file" (set_color normal)
    else
        _opah_info "No cache file found at: "(_opah_dim $cache_file)
    end

    printf "\n"
    _opah_success "Success! Secrets cleared"

    # Footer hint (skip if called with --quiet-footer flag)
    if not set -q _flag_quiet_footer
        _opah_hint "opah refresh" "to reload secrets from 1Password"
    end
end
