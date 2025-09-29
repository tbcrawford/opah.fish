function _secrets_clear -d "Clear cached secrets and environment variables"
    argparse 'h/help' 'q/quiet-footer' -- $argv

    if set -q _flag_help
        printf "Clear cached secrets and environment variables\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    secrets clear [OPTIONS]\n\n"
        printf "%s%s%s\n" (set_color --bold) "OPTIONS:" (set_color normal)
        printf "    -h, --help            Show this help message\n"
        printf "    -q, --quiet-footer    Skip the footer help message\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    secrets clear                # Clear all cached secrets and unset environment variables%s\n" (set_color --dim) (set_color normal)
        printf "%s    secrets clear --quiet-footer # Clear secrets without showing footer hint%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    set -l cache_file "$__fish_cache_dir/1password-secrets/secrets.fish"
    set -l cleared_count 0

    printf "🗑️ Clearing cached secrets...\n"

    # Unset environment variables first
    if test -f "$cache_file"
        printf "%s  - Unsetting environment variables...%s\n" (set_color --dim) (set_color normal)
        grep "^set -gx" "$cache_file" 2>/dev/null | while read -l line
            set -l key (echo $line | string replace -r '^set -gx (\w+) .*' '$1')
            if set -q $key
                set -e $key
                set cleared_count (math $cleared_count + 1)
                printf "%s    →%s Unset: %s%s%s\n" (set_color --dim) (set_color normal) (set_color --bold) "$key" (set_color normal)
            end
        end

        # Remove cache file
        printf "\n%s  - Removing cache file...%s\n" (set_color --dim) (set_color normal)
        rm -f "$cache_file"
        printf "    %s✓%s Cache file removed: %s%s%s\n" (set_color green) (set_color normal) (set_color --dim) "$cache_file" (set_color normal)
    else
        printf "ℹ️ No cache file found at: %s%s%s\n" (set_color --dim) "$cache_file" (set_color normal)
    end

    printf "\n%s%s✓ Success!%s Secrets cleared\n" (set_color green) (set_color --bold) (set_color normal)

    # Footer hint (skip if called with --quiet-footer flag)
    if not set -q _flag_quiet_footer
        printf "\n%s" (set_color --dim)
        printf "Run 'secrets refresh' to reload secrets from 1Password%s\n" (set_color normal)
    end
end
