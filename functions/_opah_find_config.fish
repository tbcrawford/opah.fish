function _opah_find_config -d "Find the first existing opah configuration file"
    # Define possible secret file locations in order of preference
    set -l secret_paths \
        "$HOME/.config/fish/secrets.yaml" \
        "$HOME/.config/fish/secrets.yml" \
        "$HOME/.config/fish/.secrets.yaml" \
        "$HOME/.config/fish/.secrets.yml" \
        "$HOME/.config/1password-secrets/secrets.yaml" \
        "$HOME/.config/1password-secrets/secrets.yml"
    
    # Find the first existing secrets file
    for path in $secret_paths
        if test -f "$path"
            echo "$path"
            return 0
        end
    end
    
    # If no file found, return error
    return 1
end