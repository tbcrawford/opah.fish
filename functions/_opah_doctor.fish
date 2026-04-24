#
# Diagnose and validate complete setup
#
# Performs comprehensive diagnostics of the opah setup including checking
# for 1Password CLI installation, authentication status, configuration file
# existence and validity, cache status, and YAML parsing. Provides detailed
# feedback about each component and suggests fixes for any issues found.
#
# @param -h/--help Shows usage information and examples
# @return 0 if all checks pass, 1 if any issues are detected
#
function _opah_doctor -d "Diagnose and validate complete setup"
    functions -q _opah_success; or source (status dirname)/_opah_ui.fish
    functions -q _opah_get_config_paths; or source (status dirname)/_opah_paths.fish
    functions -q _opah_mtime; or source (status dirname)/_opah_platform.fish
    functions -q _opah_parse_yaml; or source (status dirname)/_opah_parse_yaml.fish
    functions -q _opah_cache_count; or source (status dirname)/_opah_cache.fish

    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Diagnose and validate complete setup\n\n"
        printf "%sUSAGE:%s\n" (set_color --bold) (set_color normal)
        printf "    opah doctor\n\n"
        printf "%sEXAMPLES:%s\n" (set_color --bold) (set_color normal)
        printf "%s    opah doctor    # Run comprehensive diagnostics%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    set -l all_good true

    # Check 1Password CLI
    printf "🔍 Checking 1Password CLI...\n"
    if command -q op
        printf "  "
        _opah_success "1Password CLI (op) is installed"
        set -l op_version (op --version 2>/dev/null; or echo "unknown")
        printf "    %sVersion: %s%s\n" (set_color --dim) "$op_version" (set_color normal)
    else
        printf "  "
        _opah_error "1Password CLI (op) is not installed"
        printf "    %sInstall from: https://developer.1password.com/docs/cli/get-started/%s\n" (set_color --dim) (set_color normal)
        set all_good false
    end

    printf "\n"

    # Check 1Password authentication
    printf "🔍 Checking 1Password authentication...\n"
    if op account list >/dev/null 2>&1
        printf "  "
        _opah_success "Signed in to 1Password"
        # Extract email addresses from JSON output using Fish string builtins
        set -l accounts (op account list --format=json 2>/dev/null \
            | string match -r '"email":\s*"[^"]+"' \
            | string replace -r '"email":\s*"([^"]+)"' '$1' \
            | string join ", ")
        if test -z "$accounts"
            set accounts "Unable to parse accounts"
        end
        printf "    %sAccounts: %s%s\n" (set_color --dim) "$accounts" (set_color normal)
    else
        printf "  "
        _opah_warning "Not signed in to 1Password"
        printf "    %sRun: op signin%s\n" (set_color --dim) (set_color normal)
        printf "    %s(This will be done automatically when refreshing secrets)%s\n" (set_color --dim) (set_color normal)
    end

    printf "\n"

    # Check configuration file
    printf "🔍 Checking configuration file...\n"
    
    set -l secret_paths (_opah_get_config_paths)

    set -l config_file ""
    for path in $secret_paths
        if test -f "$path"
            set config_file "$path"
            break
        end
    end

    if test -n "$config_file"
        printf "  "
        _opah_success "Configuration file found: "(_opah_dim $config_file)

        # Quick validation: check for secrets section first, then count
        if not _opah_parse_yaml "$config_file" >/dev/null 2>&1
            printf "  "
            _opah_warning "Configuration file missing 'secrets:' section"
            set all_good false
        else
            set -l secret_count 0
            _opah_parse_yaml "$config_file" | while read -l key value
                set secret_count (math $secret_count + 1)
            end
            printf "    %sFormat: Valid YAML with secrets section%s\n" (set_color --dim) (set_color normal)
            printf "    %s1Password references: %s%s\n" (set_color --dim) "$secret_count" (set_color normal)
        end
    else
        printf "  "
        _opah_error "No configuration file found"
        printf "    %sCreate: %s%s\n" (set_color --dim) "$HOME/.config/fish/secrets.yaml" (set_color normal)
        set all_good false
    end

    printf "\n"

    # Check cache directory and file
    printf "🔍 Checking cache system...\n"
    set -l cache_dir (_opah_get_cache_dir)
    set -l cache_file (_opah_get_cache_file)

    if test -d "$cache_dir"
        printf "  "
        _opah_success "Cache directory exists: "(_opah_dim $cache_dir)
    else
        printf "  "
        _opah_warning "Cache directory missing (will be created automatically)"
    end

    if test -f "$cache_file"
        printf "  "
        _opah_success "Cache file exists: "(_opah_dim $cache_file)
        printf "    %sLast updated: %s%s\n" (set_color --dim) (_opah_mtime "$cache_file") (set_color normal)
        set -l cached_secrets (_opah_cache_count "$cache_file")
        printf "    %sCached secrets: %s%s\n" (set_color --dim) "$cached_secrets" (set_color normal)
        
        # Check cache file permissions
        set -l cache_perms (_opah_perms "$cache_file")
        if test "$cache_perms" = "600"
            printf "    %sPermissions: Secure (600)%s\n" (set_color --dim) (set_color normal)
        else
            printf "    %sPermissions: %s (should be 600)%s\n" (set_color yellow) "$cache_perms" (set_color normal)
        end
    else
        printf "  "
        _opah_warning "Cache file missing (run 'opah refresh' to create)"
    end

    printf "\n"

    # Check Fish shell integration
    printf "🔍 Checking Fish shell integration...\n"
    # Test that core functions are available
    if functions -q _opah_load
        printf "  "
        _opah_success "Core functions are available"
    else
        printf "  "
        _opah_error "Core functions not loaded"
        set all_good false
    end

    printf "\n"

    # Summary
    printf "📋 Summary\n"
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    if test "$all_good" = true
        _opah_success "All systems operational!"
        
        printf "\n%sNext steps:%s\n" (set_color --dim) (set_color normal)
        printf "    %sRun 'opah refresh' to load secrets from 1Password%s\n" (set_color --dim) (set_color normal)
        printf "    %sRun 'opah status' to verify loaded secrets%s\n" (set_color --dim) (set_color normal)
    else
        printf "%s⚠ Some issues detected. Please address the items marked with ✗ above.%s\n\n" (set_color yellow) (set_color normal)
        printf "%sCommon fixes:%s\n" (set_color --dim) (set_color normal)
        printf "    %sInstall 1Password CLI: brew install 1password-cli%s\n" (set_color --dim) (set_color normal)
        printf "    %sCreate config file: touch %s%s\n" (set_color --dim) "$HOME/.config/fish/secrets.yaml" (set_color normal)
        printf "    %sSign in to 1Password: op signin%s\n" (set_color --dim) (set_color normal)
    end
end
