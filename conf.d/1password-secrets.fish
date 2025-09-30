# 1Password Secrets Auto-loader
# This configuration file automatically loads secrets from 1Password on shell startup
# It will use cached secrets if available, or fetch from 1Password if cache is missing/empty

# Define colors and styles for consistent messaging
set -l RESET (set_color normal)
set -l BOLD (set_color -o)
set -l DIM (set_color -d)
set -l RED (set_color red)
set -l YELLOW (set_color yellow)
set -l GRAY (set_color brblack)

# Load secrets from 1Password CLI with caching
# This will only prompt for 1Password login when cache is missing/empty
if not _opah_load
    echo "$RED✗$RESET $BOLD""Failed to load 1Password secrets$RESET" >&2
    echo "$GRAY  ⚠ Some functionality may be limited until secrets are available$RESET" >&2
    echo "$DIM  💡 Run 'opah status' to check configuration$RESET" >&2
end
