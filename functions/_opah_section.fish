# Print a section header.
#
# Prints a blank line then the title in bold brcyan (title case expected from
# caller). One blank line between sections; none before the first section is
# acceptable as it adds visual breathing room after the shell prompt.
#
# @param argv Section title string (caller provides title case)
#
function _opah_section -d "Print section header: bold cyan title"
    set -q __OPAH_COLOR_RESET; or _opah_ui
    printf "\n%s%s%s\n" $__OPAH_COLOR_BOLD "$argv" $__OPAH_COLOR_RESET
end
