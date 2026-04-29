# Print the brand header and separator rule.
#
# Called ONLY from _opah_show_help. All other subcommands start output
# directly without a title or rule.
#
function _opah_header -d "Print brand header and separator (help screen only)"
    set -q __OPAH_COLOR_RESET; or _opah_ui
    printf "%sopah%s  %s1password secrets manager%s\n" \
        $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET \
        $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
    printf "%s────────────────────────────%s\n" \
        $__OPAH_COLOR_SEP $__OPAH_COLOR_RESET
end
