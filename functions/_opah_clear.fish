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
    # Ensure UI functions are available
    if not functions -q _opah_ui
        source (status dirname)/_opah_ui.fish
    end
    
    argparse 'h/help' 'q/quiet-footer' -- $argv

    if set -q _flag_help
        printf "Clear cached secrets and environment variables\n\n"
        printf "%sUSAGE:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    opah clear [OPTIONS]\n\n"
        printf "%sOPTIONS:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "    -h, --help            Show this help message\n"
        printf "    -q, --quiet-footer    Skip the footer help message\n\n"
        printf "%sEXAMPLES:%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        printf "%s    opah clear                # Clear all cached secrets%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        printf "%s    opah clear --quiet-footer # Clear without showing footer%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    set -l cache_file "$__fish_cache_dir/opah/secrets.fish"
    set -l cleared_count 0

    _opah_process "Clearing cached secrets..."

    # Unset environment variables first
    if test -f "$cache_file"
        printf "\n  %sUnsetting environment variables...%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
            set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
            if set -q $key
                set -e $key
                set cleared_count (math $cleared_count + 1)
                printf "    %s%s%s %s✓%s\n" $__OPAH_COLOR_DIM "$key" $__OPAH_COLOR_RESET $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
            end
        end

        # Remove cache file
        printf "\n  %sRemoving cache file...%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        rm -f "$cache_file"
        printf "    %s✓%s Cache file removed: %s%s%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM "$cache_file" $__OPAH_COLOR_RESET
    else
        _opah_info "No cache file found at: $(_opah_dim $cache_file)"
    end

    printf "\n"
    _opah_success "Success! Secrets cleared"

    # Footer hint (skip if called with --quiet-footer flag)
    if not set -q _flag_quiet_footer
        _opah_hint "opah refresh" "to reload secrets from 1Password"
    end
end
