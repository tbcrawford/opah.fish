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
    set -l secrets_file (_secrets_find_config 2>/dev/null)
    if test $status -eq 0
        # Create a simple handler that just prints the key name
        function __completion_handler
            echo $argv[1]
        end
        _secrets_parse_yaml "$secrets_file" __completion_handler 2>/dev/null
    end
end

# Completions for secret names in status and refresh subcommands
complete -c secrets -f -n "__fish_seen_subcommand_from status" -a "(__fish_secrets_get_cached_names)" -d "Cached secret"
complete -c secrets -f -n "__fish_seen_subcommand_from refresh" -a "(__fish_secrets_get_config_names)" -d "Secret from config"
