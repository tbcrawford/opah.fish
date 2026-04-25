#
# Display the main opah help screen.
#
# The help screen is the only place that renders the brand header and
# separator rule. All other subcommands start output directly without
# a title line. Section labels use title case.
#
function _opah_show_help -d "Display opah help screen"
    _opah_header

    _opah_section "Usage"
    printf "  %sopah%s %s<command>%s %s[options]%s\n" \
        $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET

    _opah_section "Commands"
    printf "  %sstatus    %s%sshow cached secrets%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %srefresh   %s%spull secrets from 1password%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sclear     %s%sclear cache and env vars%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sconfig    %s%sshow and validate config%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sdoctor    %s%sdiagnose setup%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sreinit    %s%sre-initialize after auth changes%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %shelp      %s%sshow this message%s\n" \
        $__OPAH_COLOR_INFO $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET

    _opah_section "Examples"
    printf "  %sopah status             # show all cached secrets%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sopah refresh            # pull all secrets%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "  %sopah doctor             # run diagnostics%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET

    printf "\n%s  run 'opah <command> --help' for details%s\n" \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
end
