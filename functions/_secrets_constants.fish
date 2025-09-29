function _secrets_constants -d "Set shared color and icon constants for 1password-secrets plugin"
    # Color constants
    set -g SECRETS_RED '\033[0;31m'
    set -g SECRETS_GREEN '\033[0;32m'
    set -g SECRETS_YELLOW '\033[0;33m'
    set -g SECRETS_BLUE '\033[0;34m'
    set -g SECRETS_PURPLE '\033[0;35m'
    set -g SECRETS_CYAN '\033[0;36m'
    set -g SECRETS_GRAY '\033[0;90m'
    set -g SECRETS_BOLD '\033[1m'
    set -g SECRETS_DIM '\033[2m'
    set -g SECRETS_RESET '\033[0m'
    
    # Icon constants
    set -g SECRETS_CHECK_MARK "✓"
    set -g SECRETS_CROSS_MARK "✗"
    set -g SECRETS_WARNING_ICON "⚠"
    set -g SECRETS_INFO_ICON ℹ
    set -g SECRETS_LOCK_ICON "🔐"
    set -g SECRETS_CONFIG_ICON "⚙️"
    set -g SECRETS_FILE_ICON "📄"
    set -g SECRETS_CLOCK_ICON "🕐"
    set -g SECRETS_ARROW "→"
end