function secrets -d "1Password Secrets Management CLI"
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
            echo "Unknown subcommand: $subcommand" >&2
            echo "Run 'secrets help' for usage information." >&2
            return 1
    end
end