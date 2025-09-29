function secrets -d "1Password Secrets Management CLI"
    # Color and formatting constants
    set -l RED '\033[0;31m'
    set -l RESET '\033[0m'
    set -l CROSS_MARK "✗"

    set -l subcommand $argv[1]

    switch $subcommand
        case status
            _secrets_status $argv[2..]
        case refresh
            _secrets_refresh $argv[2..]
        case clear
            _secrets_clear $argv[2..]
        case config
            _secrets_config $argv[2..]
        case doctor
            _secrets_doctor $argv[2..]
        case reinit
            _secrets_reinit $argv[2..]
        case help
            _secrets_show_help
        case ""
            _secrets_show_help
        case "*"
            printf "$RED$CROSS_MARK$RESET Unknown subcommand: $subcommand\n" >&2
            printf "Run 'secrets help' for usage information.\n" >&2
            return 1
    end
end
