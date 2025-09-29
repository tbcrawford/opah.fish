# Completions for the secrets command
# 1Password Secrets Management CLI

# Main subcommands
complete -c secrets -f -n __fish_use_subcommand -a status -d "Show status of cached secrets and configuration"
complete -c secrets -f -n __fish_use_subcommand -a refresh -d "Refresh secrets from 1Password"
complete -c secrets -f -n __fish_use_subcommand -a clear -d "Clear cached secrets and environment variables"
complete -c secrets -f -n __fish_use_subcommand -a config -d "Show configuration file information and validate format"
complete -c secrets -f -n __fish_use_subcommand -a doctor -d "Diagnose and validate complete setup"
complete -c secrets -f -n __fish_use_subcommand -a reinit -d "Re-initialize plugin (useful after authentication changes)"
complete -c secrets -f -n __fish_use_subcommand -a help -d "Show help message"

# Help flag for all subcommands
complete -c secrets -f -n "__fish_seen_subcommand_from status refresh clear config doctor reinit" -l help -d "Show help for subcommand"

# Function to get cached secret names from cache file
function __fish_secrets_get_cached_names
    set -l cache_file "$HOME/.cache/fish/1password-secrets/secrets.fish"
    if test -f "$cache_file"
        grep "^set -gx" "$cache_file" 2>/dev/null | string replace -r '^set -gx (\w+) .*' '$1'
    end
end

# Function to get secret names from configuration file
function __fish_secrets_get_config_names
    set -l secret_paths \
        "$HOME/.config/fish/secrets.yaml" \
        "$HOME/.config/fish/secrets.yml" \
        "$HOME/.config/fish/.secrets.yaml" \
        "$HOME/.config/fish/.secrets.yml" \
        "$HOME/.config/1password-secrets/secrets.yaml" \
        "$HOME/.config/1password-secrets/secrets.yml"

    set -l secrets_file ""
    for path in $secret_paths
        if test -f "$path"
            set secrets_file "$path"
            break
        end
    end

    if test -n "$secrets_file"
        # Parse YAML to extract secret names
        set -l in_secrets_section false
        set -l base_indent ""

        while read -l line
            if test -z "$line"; or string match -q "#*" "$line"
                continue
            end

            if string match -q "secrets:" "$line"
                set in_secrets_section true
                set base_indent (string match -r "^(\s*)" "$line" | string sub -s 2)
                continue
            end

            if test "$in_secrets_section" = true
                set -l current_indent (string match -r "^(\s*)" "$line" | string sub -s 2)

                if test (string length "$current_indent") -le (string length "$base_indent"); and string match -q "*:*" "$line"
                    set in_secrets_section false
                    continue
                end

                if test (string length "$current_indent") -gt (string length "$base_indent"); and string match -q "*:*" "$line"
                    set -l key_value (string split -m 1 ":" "$line")
                    set -l key (string trim $key_value[1])
                    if test -n "$key"
                        echo $key
                    end
                end
            end
        end <"$secrets_file"
    end
end

# Completions for secret names in status and refresh subcommands
complete -c secrets -f -n "__fish_seen_subcommand_from status" -a "(__fish_secrets_get_cached_names)" -d "Cached secret"
complete -c secrets -f -n "__fish_seen_subcommand_from refresh" -a "(__fish_secrets_get_config_names)" -d "Secret from config"
