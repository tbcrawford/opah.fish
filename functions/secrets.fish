function secrets -d "1Password Secrets Management CLI"
    _secrets_constants

    argparse 'h/help' -- $argv
    if set -q _flag_help
        _secrets_show_help
        return 0
    end

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
            printf "$SECRETS_RED$SECRETS_CROSS_MARK$SECRETS_RESET Unknown subcommand: $subcommand\n" >&2
            printf "Run 'secrets help' for usage information.\n" >&2
            return 1
    end
end
