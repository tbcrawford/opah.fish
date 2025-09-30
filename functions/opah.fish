#
# 1Password Secrets Management CLI
#
# Main entry point for the opah CLI tool. Routes subcommands to their
# corresponding implementation functions. Provides a unified interface for
# managing 1Password secrets in the Fish shell.
#
# @param subcommand The subcommand to execute (status, refresh, clear, config, doctor, reinit, help)
# @param argv Additional arguments passed to the subcommand
# @return 0 on success, 1 if unknown subcommand
#
function opah -d "1Password Secrets Management CLI"
    # Ensure UI functions are available
    if not functions -q _opah_ui
        source (status dirname)/_opah_ui.fish
    end
    
    set -l subcommand $argv[1]
    
    # Handle -h/--help only when there's no subcommand
    if test "$subcommand" = "-h"; or test "$subcommand" = "--help"
        _opah_show_help
        return 0
    end

    switch $subcommand
        case status
            _opah_status $argv[2..]
        case refresh
            _opah_refresh $argv[2..]
        case clear
            _opah_clear $argv[2..]
        case config
            _opah_config $argv[2..]
        case doctor
            _opah_doctor $argv[2..]
        case reinit
            _opah_reinit $argv[2..]
        case ""
            _opah_show_help
        case help
            _opah_show_help
        case "*"
            _opah_error "Unknown subcommand: $subcommand" >&2
            _opah_hint "opah help" "for usage information" >&2
            return 1
    end
end
