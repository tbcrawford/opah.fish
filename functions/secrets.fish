function secrets -d "1Password Secrets Management CLI"
    # Ensure UI functions are available
    if not functions -q _secrets_ui
        source (status dirname)/_secrets_ui.fish
    end
    
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
            _secrets_error "Unknown subcommand: $subcommand" >&2
            _secrets_hint "secrets help" "for usage information" >&2
            return 1
    end
end
