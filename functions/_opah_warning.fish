# Print warning message with ▲ sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line
#
function _opah_warning -d "Print warning: ▲ msg [detail]"
    set -q __OPAH_COLOR_RESET; or _opah_ui
    printf "%s ▲ %s%s\n" $__OPAH_COLOR_WARNING $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end
