# Print success message with ● sigil.
#
# @param argv[1] Primary message
# @param argv[2] Optional detail line (printed indented and dim)
#
function _opah_success -d "Print success: ● msg [detail]"
    set -q __OPAH_COLOR_RESET; or _opah_ui
    printf "%s ● %s%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET "$argv[1]"
    if set -q argv[2]
        printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv[2]" $__OPAH_COLOR_RESET
    end
end
