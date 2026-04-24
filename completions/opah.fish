# Completions for the opah command
# 1Password Secrets Management CLI

# Main subcommands
complete -c opah -f -n __fish_use_subcommand -a status -d "Show status of cached secrets and configuration"
complete -c opah -f -n __fish_use_subcommand -a refresh -d "Refresh secrets from 1Password"
complete -c opah -f -n __fish_use_subcommand -a clear -d "Clear cached secrets and environment variables"
complete -c opah -f -n __fish_use_subcommand -a config -d "Show configuration file information and validate format"
complete -c opah -f -n __fish_use_subcommand -a doctor -d "Diagnose and validate complete setup"
complete -c opah -f -n __fish_use_subcommand -a reinit -d "Re-initialize plugin (useful after authentication changes)"
complete -c opah -f -n __fish_use_subcommand -a help -d "Show help message"

# Help flag for all subcommands
complete -c opah -f -n "__fish_seen_subcommand_from status refresh clear config doctor reinit" -l help -d "Show help for subcommand"

# Function to get cached secret names from cache file
function __fish_opah_get_cached_names
    set -l cache_file (_opah_get_cache_file 2>/dev/null)
    if test -f "$cache_file"
        # Read tab-separated cache format: KEY<tab>VALUE
        _opah_cache_keys "$cache_file" 2>/dev/null
    end
end

# Function to get secret names from configuration file
function __fish_opah_get_config_names
    set -l secrets_file (_opah_find_config 2>/dev/null)
    if test $status -eq 0
        # Stream-based parsing outputs: KEY<tab>VALUE
        _opah_parse_yaml "$secrets_file" 2>/dev/null | while read -l key value
            echo $key
        end
    end
end

# Completions for secret names in status and refresh subcommands
complete -c opah -f -n "__fish_seen_subcommand_from status" -a "(__fish_opah_get_cached_names)" -d "Cached secret"
complete -c opah -f -n "__fish_seen_subcommand_from refresh" -a "(__fish_opah_get_config_names)" -d "Secret from config"
