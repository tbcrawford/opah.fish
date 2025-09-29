function secrets -d "1Password Secrets Management CLI"
    set -l subcommand $argv[1]
    
    # Handle -h/--help only when there's no subcommand
    if test "$subcommand" = "-h"; or test "$subcommand" = "--help"
        _secrets_show_help
        return 0
    end

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
        case ""
            _secrets_show_help
        case help
            _secrets_show_help
        case "*"
            printf "%s✗%s Unknown subcommand: $subcommand\n" (set_color red) (set_color normal) >&2
            printf "Run 'secrets help' for usage information.\n" >&2
            return 1
    end
end
