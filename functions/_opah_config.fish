#
# Show configuration file information and validate format
#
# Displays information about the opah configuration file location and
# validates its format. Shows all possible configuration file locations
# and indicates which ones exist. Parses and validates the YAML structure
# of the configuration file if found.
#
# @param -h/--help Shows usage information and examples
# @return 0 on success, 1 if no configuration file is found or validation fails
#
function _opah_config -d "Show configuration file information and validate format"
    functions -q _opah_success; or source (status dirname)/_opah_ui.fish
    functions -q _opah_get_config_paths; or source (status dirname)/_opah_paths.fish
    functions -q _opah_find_config; or source (status dirname)/_opah_find_config.fish
    functions -q _opah_mtime; or source (status dirname)/_opah_platform.fish
    functions -q _opah_parse_yaml; or source (status dirname)/_opah_parse_yaml.fish

    argparse 'h/help' -- $argv

    if set -q _flag_help
        printf "Show configuration file information and validate format\n\n"
        printf "%sUSAGE:%s\n" (set_color --bold) (set_color normal)
        printf "    opah config\n\n"
        printf "%sEXAMPLES:%s\n" (set_color --bold) (set_color normal)
        printf "%s    opah config    # Show config file info and validate format%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    # Get possible secret file locations
    set -l secret_paths (_opah_get_config_paths)

    printf "Checking configuration file locations:\n"
    for path in $secret_paths
        if test -f "$path"
            _opah_success (_opah_dim $path)" (FOUND)"
        else
            _opah_error (_opah_dim $path)
        end
    end

    printf "\n"

    # Find config file
    set -l config_file (_opah_find_config)
    if test $status -ne 0
        _opah_error "Error: No configuration file found!"
        printf "\nCreate a opah configuration file at one of these locations:\n"
        printf "%s  %s (recommended)%s\n" (set_color --dim) "$HOME/.config/fish/secrets.yaml" (set_color normal)
        printf "\n%sExample format:%s\n" (set_color --bold) (set_color normal)
        printf "%s    secrets:%s\n" (set_color --dim) (set_color normal)
        printf "%s      API_KEY: \"op://vault/MyVault/API Keys/api_key\"%s\n" (set_color --dim) (set_color normal)
        printf "%s      DATABASE_URL: \"op://vault/MyVault/Database/connection_string\"%s\n" (set_color --dim) (set_color normal)
        return 1
    end

    _opah_file "Active configuration file: "(_opah_dim $config_file)
    _opah_info "Last modified: "(_opah_dim (_opah_mtime "$config_file"))

    # Validate YAML format and show secrets
    printf "\nConfiguration validation:\n"

    # First check if the file is valid (has a secrets section) before displaying
    if not _opah_parse_yaml "$config_file" >/dev/null 2>&1
        _opah_error "Error: No 'secrets:' section found in configuration file"
        return 1
    end

    set -l config_count 0

    # Process secrets stream (parser already validated above)
    _opah_parse_yaml "$config_file" | while read -l key value
        set config_count (math $config_count + 1)

        if string match -q "op://*" "$value"
            printf "    %s✓%s %s%s:%s %s%s%s\n" (set_color green) (set_color normal) (set_color --dim) "$key" (set_color normal) (set_color --dim) "$value" (set_color normal)
        else
            printf "    %s⚠%s %s%s:%s %s%s%s %s(not a 1Password reference)%s\n" (set_color yellow) (set_color normal) (set_color --dim) "$key" (set_color normal) (set_color --dim) "$value" (set_color normal) (set_color --dim) (set_color normal)
        end
    end

    printf "\n"
    _opah_success "Success! Configuration valid"
    _opah_info "Found "(_opah_dim $config_count)" secret(s) defined"
end
