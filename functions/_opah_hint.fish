# Print a hint line (actionable suggestion).
#
# Indented 5 spaces (aligns under sigil message text). No sigil. Dim.
#
# @param argv Full hint string, e.g. "run: opah refresh to reload secrets"
#
function _opah_hint -d "Print hint: dim indented suggestion"
    set -q __OPAH_COLOR_RESET; or _opah_ui
    printf "%s     %s%s\n" $__OPAH_COLOR_DIM "$argv" $__OPAH_COLOR_RESET
end
