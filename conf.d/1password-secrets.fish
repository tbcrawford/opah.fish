# 1Password Secrets Auto-loader
# This configuration file automatically loads secrets from 1Password on shell startup
# It will use cached secrets if available, or fetch from 1Password if cache is missing/empty

# Load secrets from 1Password CLI with caching
# This will only prompt for 1Password login when cache doesn't exist
if not _load_secrets
    echo "Warning: Failed to load secrets from 1Password CLI" >&2
    echo "Some functionality may be limited" >&2
end